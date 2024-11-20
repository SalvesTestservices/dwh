class Dw::Tasks::EtlBbInvoicesTask < Dw::Tasks::BaseTask
  queue_as :default

  def perform(account, run, result, task)
    # Wait for alle dependencies to finish
    all_dependencies_finished = wait_on_dependencies(account, run, task)
    if all_dependencies_finished == false
      Dw::DataPipelineLogger.new.create_log(run.id, "cancelled", "[#{account.name}] Taak [#{task.task_key}] geannuleerd")
      result.update(finished_at: DateTime.now, status: "cancelled")
      return
    end

    begin
      # Extract invoices
      ActsAsTenant.without_tenant do
        account     = Account.find(run.account_id)
        invoices = account.invoices.includes(:invoice_lines).where.not(company_id: get_excluded_company_ids)  
        unless invoices.blank?
          invoices.each do |invoice|
            invoice_hash = Hash.new
  
            invoice_date = invoice.invoice_date.blank? ? nil : invoice.invoice_date.strftime("%d%m%Y").to_i
  
            if invoice.project_id.blank? or invoice.project.blank? or invoice.project.customer_id.blank?
              customer_id = nil
            else
              customer_id = invoice.project.customer_id
            end
  
            if invoice.timesheet.present?
              timesheet_month = invoice.timesheet.month
              timesheet_year = invoice.timesheet.year
            else
              timesheet_month = nil
              timesheet_year = nil
            end
  
            internal_charging = invoice.internal_charging == "0" ? false : true
  
            unless invoice.invoice_lines.blank?
              amount_excl_vat = 0.0
              vat_6 = 0.0
              vat_9 = 0.0
              vat_21 = 0.0
              vat_total = 0.0
              amount_incl_vat = 0.0
  
              invoice.invoice_lines.each do |invoice_line|
                total = invoice_line.quantity * invoice_line.rate
                amount_excl_vat += total
  
                case invoice_line.vat_percentage
                when 6
                  vat_6 += total * 0.06
                  vat_total += total * 0.06
                  amount_incl_vat += total * 1.06
                when 9
                  vat_9 += total * 0.09
                  vat_total += total * 0.09
                  amount_incl_vat += total * 1.09
                when 21
                  vat_21 += total * 0.21
                  vat_total += total * 0.21
                  amount_incl_vat += total * 1.21
                end
              end
            end
  
            invoice_hash[:original_id]        = invoice.id
            invoice_hash[:invoice_date]       = invoice_date
            invoice_hash[:status]             = invoice.status
            invoice_hash[:project_id]         = invoice.project_id
            invoice_hash[:customer_id]        = customer_id
            invoice_hash[:user_id]            = invoice.user_id
            invoice_hash[:company_id]         = invoice.company_id
            invoice_hash[:timesheet_month]    = timesheet_month
            invoice_hash[:timesheet_year]     = timesheet_year
            invoice_hash[:credit]             = invoice.credit
            invoice_hash[:condition_days]     = invoice.condition_days
            invoice_hash[:internal_charging]  = internal_charging
            invoice_hash[:amount_excl_vat]    = amount_excl_vat.blank? ? nil : amount_excl_vat.round(2)
            invoice_hash[:vat_6]              = vat_6.blank? ? nil : vat_6.round(2)
            invoice_hash[:vat_9]              = vat_9.blank? ? nil : vat_9.round(2)
            invoice_hash[:vat_21]             = vat_21.blank? ? nil : vat_21.round(2)
            invoice_hash[:vat_total]          = vat_total.blank? ? nil : vat_total.round(2)
            invoice_hash[:amount_incl_vat]    = amount_incl_vat.blank? ? nil : amount_incl_vat.round(2)
  
            Dw::EtlStorage.create(account_id: account.id, identifier: "invoices", etl: "extract", data: invoice_hash)
          end
        end

        # Load invoices
        dim_account = Dw::DimAccount.find_by(original_id: account.id)

        invoices = Dw::EtlStorage.where(account_id: account.id, identifier: "invoices", etl: "extract")
        unless invoices.blank?
          invoices.each do |invoice|
            dim_project     = Dw::DimProject.find_by(account_id: dim_account.id, original_id: invoice.data['project_id'])
            dim_customer    = Dw::DimCustomer.find_by(account_id: dim_account.id, original_id: invoice.data['customer_id'])
            dim_user        = Dw::DimUser.find_by(account_id: dim_account.id, original_id: invoice.data['user_id'])
            dim_company     = Dw::DimCompany.find_by(account_id: dim_account.id, original_id: invoice.data['company_id'])
            
            dim_project_id      = dim_project.blank? ? nil : dim_project.id
            dim_customer_id     = dim_customer.blank? ? nil : dim_customer.id
            dim_user_id         = dim_user.blank? ? nil : dim_user.id
            dim_company_id      = dim_company.blank? ? nil : dim_company.id
    
            Dw::FactInvoice.upsert({ account_id: dim_account.id, original_id: invoice.data['original_id'], invoice_date: invoice.data['invoice_date'], status: invoice.data['status'], project_id: dim_project_id,
              customer_id: dim_customer_id, user_id: dim_user_id, company_id: dim_company_id, timesheet_month: invoice.data['timesheet_month'], timesheet_year: invoice.data['timesheet_year'], credit: invoice.data['credit'],
              condition_days: invoice.data['condition_days'], internal_charging: invoice.data['internal_charging'], amount_excl_vat: invoice.data['amount_excl_vat'], vat_6: invoice.data['vat_6'], vat_9: invoice.data['vat_9'],
              vat_21: invoice.data['vat_21'], vat_total: invoice.data['vat_total'], amount_incl_vat: invoice.data['amount_incl_vat'] }, unique_by: [:account_id, :original_id])
    
            invoice.destroy
          end
        end
      end

      # Update result
      result.update(finished_at: DateTime.now, status: "finished")
      Dw::DataPipelineLogger.new.create_log(run.id, "success", "[#{account.name}] Finished task [#{task.task_key}] successfully")
    rescue => e
      # Update result to failed if an error occurs
      result.update(finished_at: DateTime.now, status: "failed", error: e.message)
      Dw::DataPipelineLogger.new.create_log(run.id, "alert", "[#{account.name}] Finished task [#{task.task_key}] with error: #{e.message}")
    end
  end
end
