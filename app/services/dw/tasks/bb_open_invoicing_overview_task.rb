class Dwh::Tasks::BbOpenInvoicingOverviewTask < Dwh::Tasks::BaseTask
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
      ActsAsTenant.without_tenant do
        year  = run.dp_pipeline.year.blank? ? 1.month.ago.year : run.dp_pipeline.year.to_i
        month = run.dp_pipeline.month.blank? ? 1.month.ago.month : run.dp_pipeline.month.to_i

        # Remove all existing records
        Dwh::BbOpenInvoicingOverview.where(account_id: account.id).destroy_all

        # Get all invoices
        invoices = account.invoices.where.not(company_id: [2,3,4,5,8,48])

        # Timesheet invoices
        invoices = invoices.where("timesheet_id IS NOT NULL AND status != 'despatched'")
        unless invoices.blank?
          invoices.each do |invoice|
            company = Company.find_by(id: invoice.company_id)
            unless company.blank?
              timesheet = Timesheet.find(invoice.timesheet_id)
              user      = User.find(timesheet.user_id)
              project   = Project.find(invoice.project_id)
              customer  = project.customer
              status    = get_invoice_status(invoice.status)
              quantity  = invoice.invoice_lines.sum(:quantity)
              amount    = invoice.invoice_lines.sum { |invoice_line| invoice_line.quantity * invoice_line.rate }

              Dwh::BbOpenInvoicingOverview.upsert({ uid: invoice.id, category: "timesheets", account_id: account.id, company_id: company.id, user_id: user.id, customer_id: customer.id, invoice_id: invoice.id, account_name: account.name, 
                company_name: company.name, user_name: user.full_name, customer_name: customer.name, project_name: project.name, status: status, quantity: quantity, amount: amount, month: timesheet.month, year: timesheet.year}, unique_by: [:uid])
            end
          end
        end

        # Selfbilling invoices
        pselfbillings = account.pselfbillings.where(month: month, year: year, week: nil)
        unless pselfbillings.blank?

          # Get not despatched selfbilling invoices
          pselfbillings.each do |pselfbilling|
            invoice_ids = [pselfbilling.invoice_id, pselfbilling.internal_charging_invoice_id].compact
            unless invoice_ids.blank?
              invoice_ids.each do |invoice_id|
                invoice = Invoice.find_by(id: invoice_id)
                if invoice.present? and invoice.status != "despatched"
                  customer_id, customer_name = get_customer(invoice)
                  company     = Company.find_by(id: invoice.company_id)
                  user        = User.find_by(id: projectuser.user_id)
                  project     = Project.find_by(id: projectuser.project_id)
                  projectuser = Projectuser.find_by(id: pselfbilling.projectuser_id)
                  status      = get_invoice_status(invoice.status)
                  quantity    = invoice.invoice_lines.sum(:quantity)
                  amount      = invoice.invoice_lines.sum { |invoice_line| invoice_line.quantity * invoice_line.rate }
    
                  Dwh::BbOpenInvoicingOverview.upsert({ uid: invoice.id, category: "selfbilling", account_id: account.id, company_id: company.id, user_id: user.id, customer_id: customer_id, invoice_id: invoice.id, account_name: account.name, 
                    company_name: company.name, user_name: user.full_name, customer_name: customer_name, project_name: project.name, status: status, quantity: quantity, amount: amount, month: pselfbilling.month, year: pselfbilling.year }, unique_by: [:uid])              
                end  
              end
            end
          end
            
          # Get not invoiced selfbilling
          projectuser_ids = pselfbillings.map(&:projectuser_id).uniq
          unless projectuser_ids.blank?
            projectuser_ids.each do |projectuser_id|
              projectuser_pselfbillings = pselfbillings.where(projectuser_id: projectuser_id)

              merged_hours = projectuser_pselfbillings.reduce({}) do |acc, pselfbilling|
                acc.merge(pselfbilling.hours) { |key, oldval, newval| oldval.to_f + newval.to_f }
              end
  
              merged_days = projectuser_pselfbillings.reduce({}) do |acc, pselfbilling|
                acc.merge(pselfbilling.days) { |key, oldval, newval| oldval == "1" ? oldval : newval }
              end

              not_invoiced_days = merged_hours.reduce({}) do |result, (date, hours)|
                result[date] = hours unless merged_days.key?(date)
                result
              end

              unless not_invoiced_days.blank?
                pselfbilling = pselfbillings.last
                not_invoiced_days.each do |day, hours|
                  uid         = "#{pselfbilling.id}#{day}"
                  projectuser = pselfbilling.projectuser
                  project     = projectuser&.project
                  company     = project&.company
                  user        = projectuser&.user
                  customer    = project&.customer
                  rate        = RateCalculator.new(nil, pselfbilling&.projectuser, nil).calculate_rate("rate", Date.strptime(day, "%d%m%Y"))
                  amount      = (hours * rate).round(2)

                  Dwh::BbOpenInvoicingOverview.upsert({ uid: uid, category: "selfbilling", account_id: account.id, company_id: company.id, user_id: user.id, customer_id: customer.id, invoice_id: nil, account_name: account.name, 
                    company_name: company.name, user_name: user.full_name, customer_name: customer.name, project_name: project.name, status: "niet gefactureerd", quantity: hours, amount: amount, month: pselfbilling.month, year: pselfbilling.year }, unique_by: [:uid])
                end
              end
            end
          end
        end

        # Manual invoices
        invoices = invoices.where("project_id IS NULL AND status != 'despatched'")
        unless invoices.blank?
          invoices.each do |invoice|
            company = Company.find_by(id: invoice.company_id)
            unless company.blank?
              customer_id, customer_name = get_customer(invoice)
              status    = get_invoice_status(invoice.status)
              quantity  = invoice.invoice_lines.sum(:quantity)
              amount    = invoice.invoice_lines.sum { |invoice_line| invoice_line.quantity * invoice_line.rate }

              Dwh::BbOpenInvoicingOverview.upsert({ uid: invoice.id, category: "manual", account_id: account.id, company_id: company.id, user_id: nil, customer_id: customer_id, invoice_id: invoice.id, account_name: account.name, 
                company_name: company.name, user_name: nil, customer_name: customer_name, project_name: nil, status: status, quantity: quantity, amount: amount, month: invoice.created_at.month, year: invoice.created_at.year }, unique_by: [:uid])
            end
          end
        end

        # Periodic invoices
        invoices = invoices.where("periodic_invoice_id IS NOT NULL AND status != 'despatched'")
        unless invoices.blank?
          invoices.each do |invoice|
            company = Company.find_by(id: invoice.company_id)
            unless company.blank?
              customer_id, customer_name = get_customer(invoice)
              status    = get_invoice_status(invoice.status)
              quantity  = invoice.invoice_lines.sum(:quantity)
              amount    = invoice.invoice_lines.sum { |invoice_line| invoice_line.quantity * invoice_line.rate }

              Dwh::BbOpenInvoicingOverview.upsert({ uid: invoice.id, category: "periodic", account_id: account.id, company_id: company.id, user_id: nil, customer_id: customer_id, invoice_id: invoice.id, account_name: account.name, 
                company_name: company.name, user_name: nil, customer_name: customer_name, project_name: nil, status: status, quantity: quantity, amount: amount, month: invoice.created_at.month, year: invoice.created_at.year }, unique_by: [:uid])
            end
          end
        end

        # Consolidated invoices
        invoices = invoices.where("consolidated_invoice_code IS NOT NULL AND status != 'despatched'")
        unless invoices.blank?
          invoices.each do |invoice|
            company = Company.find_by(id: invoice.company_id)
            unless company.blank?
              customer_id, customer_name = get_customer(invoice)
              status    = get_invoice_status(invoice.status)
              quantity  = invoice.invoice_lines.sum(:quantity)
              amount    = invoice.invoice_lines.sum { |invoice_line| invoice_line.quantity * invoice_line.rate }

              Dwh::BbOpenInvoicingOverview.upsert({ uid: invoice.id, category: "consolidated", account_id: account.id, company_id: company.id, user_id: nil, customer_id: customer_id, invoice_id: invoice.id, account_name: account.name, 
                company_name: company.name, user_name: nil, customer_name: customer_name, project_name: nil, status: status, quantity: quantity, amount: amount, month: invoice.created_at.month, year: invoice.created_at.year }, unique_by: [:uid])
            end
          end
        end

        # Services invoices
        invoices = invoices.where("timesheet_id IS NULL AND project_id IS NOT NULL AND status != 'despatched'")
        unless invoices.blank?
          invoices.each do |invoice|
            if invoice.project.service?
              company = Company.find_by(id: invoice.company_id)
              unless company.blank?
                customer_id, customer_name = get_customer(invoice)
                status    = get_invoice_status(invoice.status)
                quantity  = invoice.invoice_lines.sum(:quantity)
                amount    = invoice.invoice_lines.sum { |invoice_line| invoice_line.quantity * invoice_line.rate }
  
                Dwh::BbOpenInvoicingOverview.upsert({ uid: invoice.id, category: "services", account_id: account.id, company_id: company.id, user_id: nil, customer_id: customer_id, invoice_id: invoice.id, account_name: account.name, 
                  company_name: company.name, user_name: nil, customer_name: customer_name, project_name: nil, status: status, quantity: quantity, amount: amount, month: invoice.created_at.month, year: invoice.created_at.year }, unique_by: [:uid])
              end
            end
          end
        end

        # Trainings invoices
        invoices = invoices.where("timesheet_id IS NULL AND project_id IS NOT NULL AND status != 'despatched'")
        unless invoices.blank?
          invoices.each do |invoice|
            if invoice.project.training?
              company = Company.find_by(id: invoice.company_id)
              unless company.blank?
                customer_id, customer_name = get_customer(invoice)
                status    = get_invoice_status(invoice.status)
                quantity  = invoice.invoice_lines.sum(:quantity)
                amount    = invoice.invoice_lines.sum { |invoice_line| invoice_line.quantity * invoice_line.rate }

                Dwh::BbOpenInvoicingOverview.upsert({ uid: invoice.id, category: "trainings", account_id: account.id, company_id: company.id, user_id: nil, customer_id: customer_id, invoice_id: invoice.id, account_name: account.name, 
                  company_name: company.name, user_name: nil, customer_name: customer_name, project_name: nil, status: status, quantity: quantity, amount: amoun, month: invoice.created_at.month, year: invoice.created_at.year }, unique_by: [:uid])
              end
            end
          end
        end

        # Fixed price invoices
        invoices = invoices.where("timesheet_id IS NULL AND project_id IS NOT NULL AND status != 'despatched'")
        unless invoices.blank?
          invoices.each do |invoice|
            if invoice.fixed_price?
              company = Company.find_by(id: invoice.company_id)
              unless company.blank?
                customer_id, customer_name = get_customer(invoice)
                status    = get_invoice_status(invoice.status)
                quantity  = invoice.invoice_lines.sum(:quantity)
                amount    = invoice.invoice_lines.sum { |invoice_line| invoice_line.quantity * invoice_line.rate }

                Dwh::BbOpenInvoicingOverview.upsert({ uid: invoice.id, category: "fixed_price", account_id: account.id, company_id: company.id, user_id: nil, customer_id: customer_id, invoice_id: invoice.id, account_name: account.name, 
                  company_name: company.name, user_name: nil, customer_name: customer_name, project_name: nil, status: status, quantity: quantity, amount: amount, month: invoice.created_at.month, year: invoice.created_at.year }, unique_by: [:uid])
              end
            end
          end
        end

        # Fixed price pturnovers
        pturnovers = account.pturnovers.where("status = 'scheduled' AND booking_date < ?", Date.current)
        unless pturnovers.blank?
          pturnovers.each do |pturnover|
            project = Project.find_by(id: pturnover.project_id)
            company = Company.find_by(id: project.company_id)
            if company.present? and [2,3,4,5,8,48].exclude?(company.id) and pturnover.turnover.present? and pturnover.turnover > 0
              customer  = project.customer

              Dwh::BbOpenInvoicingOverview.upsert({ uid: pturnover.id, category: "fixed_price_turnovers", account_id: account.id, company_id: company.id, user_id: nil, customer_id: customer.id, invoice_id: nil, account_name: account.name, 
                company_name: company.name, user_name: nil, customer_name: customer.name, project_name: project.name, status: "gepland", quantity: 1, amount: pturnover.turnover, month: pturnover.booking_date.month, year: pturnover.booking_date.year }, unique_by: [:uid])
            end
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

  private def get_customer(invoice)
    if invoice.contact_id.blank?
      customer_id = nil
      customer_name = invoice.contact_line1
    else
      customer = invoice.contact.customer
      customer_id = customer.id
      customer_name = customer.name
    end
    return customer_id, customer_name
  end

  private def get_invoice_status(status)
    I18n.with_locale(:nl) do
      case status
      when "created"
        I18n.t('.invoice.states.created').downcase
      when "adapted"
        I18n.t('.invoice.states.adapted').downcase
      when "despatchable"
        I18n.t('.invoice.states.despatchable').downcase
      when "despatched"
        I18n.t('.invoice.states.despatched').downcase
      when "overdue"
        I18n.t('.invoice.states.overdue').downcase
      when "admonished"
        I18n.t('.invoice.states.admonished').downcase
      when "company_disapproved"
        I18n.t('.invoice.states.company_disapproved').downcase
      when "admin_disapproved"
        I18n.t('.invoice.states.admin_disapproved').downcase
      when "company_approved"
        I18n.t('.invoice.states.company_approved').downcase
      when "admin_approved"
        I18n.t('.invoice.states.admin_approved').downcase
      end
    end
  end
end
