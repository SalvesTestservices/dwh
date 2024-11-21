class Dwh::Tasks::BbInvoicesOverviewTask < Dwh::Tasks::BaseTask
  queue_as :default

  def perform(account, run, result, task)
    # Wait for alle dependencies to finish
    all_dependencies_finished = wait_on_dependencies(account, run, task)
    if all_dependencies_finished == false
      Dwh::DataPipelineLogger.new.create_log(run.id, "cancelled", "[#{account.name}] Taak [#{task.task_key}] geannuleerd")
      result.update(finished_at: DateTime.now, status: "cancelled")
      return
    end

    begin
      # Set which month(s) should be iterated
      if run.dp_pipeline.year.present? and run.dp_pipeline.month.present?
        month = run.dp_pipeline.month.to_i
        year = run.dp_pipeline.year.to_i
      else
        month = Date.current.month
        year = Date.current.year
      end

      ActsAsTenant.without_tenant do
        invoices = account.invoices.where(status: "despatched").where("extract(month from invoice_date) = ? and extract(year from invoice_date) = ?", month, year).order(:invoice_nr)
        unless invoices.blank?
          invoices.each do |invoice|
            invoice_nr = invoice.invoice_nr.blank? ? "-" : invoice.invoice_nr
            invoice_date = invoice.invoice_date.blank? ? "-" : invoice.invoice_date.strftime("%d-%m-%Y")
            month = invoice.invoice_date.blank? ? "-" : invoice.invoice_date.strftime("%m")
            year = invoice.invoice_date.blank? ? "-" : invoice.invoice_date.strftime("%Y")

            invoice_lines = invoice.invoice_lines
            quantity = 0.0
            amount = 0.0
            invoice_lines.each do |line|
              quantity += line.quantity
              amount += line.quantity*line.rate
            end
            
            company = account.companies.find_by(id: invoice.company_id).blank? ? nil : account.companies.find(invoice.company_id)
            company_id = company.blank? ? "-" : company.id
            company_name = company.blank? ? "-" : company.name_short
            
            if invoice.contact.blank? or invoice.contact.customer.blank?
              customer = nil
            else
              customer = invoice.contact.customer
            end
            customer_id = customer.blank? ? "-" : customer.id
            customer_name = customer.blank? ? "-" : customer.name

            project = invoice.project.blank? ? nil : invoice.project
            project_id = project.blank? ? "-" : project.id
            
            if invoice.project.blank? or invoice.project.customer.blank?
              project_name = project.blank? ? "-" : project.name
            else
              project_name = invoice.project.customer.name
            end

            description = invoice_lines.first.description.blank? ? "-" : invoice_lines.first.description
            
            user = invoice.timesheet.blank? ? nil : invoice.timesheet.user
            user_id = user.blank? ? "-" : user.id
            user_name = user.blank? ? "-" : user.full_name

            if user.present?
              invoice_type = "hour_based"
            elsif project.present? and project.calculation_type = "fixed_price"
              invoice_type = "fixed_price"
            elsif project.present? and project.calculation_type = "service"
              invoice_type = "service"
            elsif project.present? and project.calculation_type = "training"
              invoice_type = "training"
            else
              invoice_type = "manual"
            end

            Dwh::BbInvoiceOverview.upsert({ uid: invoice.id, account_id: account.id, company_id: company.id, user_id: user_id, customer_id: customer_id, invoice_id: invoice.id, project_id: project_id,
                  account_name: account.name, company_name: company_name, invoice_nr: invoice_nr, invoice_date: invoice_date, month: month, year: year, user_name: user_name, customer_name: customer_name,
                  project_name: project_name, description: description, quantity: quantity, amount: amount, invoice_type: invoice_type}, unique_by: [:uid])
          end
        end
      end

      # Update result
      result.update(finished_at: DateTime.now, status: "finished")
      Dwh::DataPipelineLogger.new.create_log(run.id, "success", "[#{account.name}] Finished task [#{task.task_key}] successfully")
    rescue => e
      # Update result to failed if an error occurs
      result.update(finished_at: DateTime.now, status: "failed", error: e.message)
      Dwh::DataPipelineLogger.new.create_log(run.id, "alert", "[#{account.name}] Finished task [#{task.task_key}] with error: #{e.message}")
    end
  end
end
