class Dw::Tasks::BbGroupedWorkOverviewTask < Dw::Tasks::BaseTask
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
      ActsAsTenant.without_tenant do
        targets = ["own","from_others","to_others","subcos","services","internally_charged","projects","trainings","consolidated_invoices","invoices"]
        vat = Vat.where(selected: true).first

        # Remove rows with zero hours of previous month
        Dw::BbGroupedWorkOverview.where(account_id: account.id, month: 1.month.ago.month, year: 1.month.ago.year).where(hours: 0.0).destroy_all
        
        # Set which month(s) should be iterated
        if run.dp_pipeline.year.present? and run.dp_pipeline.month.present?
          month_iterations = [Date.new(run.dp_pipeline.year.to_i, run.dp_pipeline.month.to_i, 1)]
        else
          month_iterations = [1.month.ago.beginning_of_month,Date.today.beginning_of_month]
        end

        # Iterate over all months
        month_iterations.each do |month_iteration|
          year                = month_iteration.year
          month               = month_iteration.month
          first_day_of_month  = Date.new(year,month,1)
          last_day_of_month   = first_day_of_month.end_of_month

          companies = account.companies.active.where.not(id: [8, 2, 48])
          companies.each do |company|
            targets.each do |target|
              if target == "own" or target == "from_others" or target == "to_others" or target == "subcos"
                 # Scope users 
                if run.dp_pipeline.scoped_user_id.present?
                  users = User.where(id: run.dp_pipeline.scoped_user_id.to_i)
                else
                  users = User.where("role = 'employee' OR role = 'manager' OR role = 'external' OR role = 'mc' OR role = 'dm'").order(:first_name, :last_name)
                  users = users.where("start_date <= ? and (leave_date IS NULL or leave_date >= ?)", last_day_of_month, first_day_of_month)
                end

                iterated_users = UsersIterator.new(users, vat, company.id).create_assignment_iterations(month, year)

                total_hours = 0.0
                total_turnover_excl_vat = 0.0
                total_vat = 0.0
                total_turnover_incl_vat = 0.0
      
                group_totals = {
                  "consultants_internal" => { hours: 0.0, turnover_excl_vat: 0.0, vat: 0.0, turnover_incl_vat: 0.0 },
                  "consultants_external" => { hours: 0.0, turnover_excl_vat: 0.0, vat: 0.0, turnover_incl_vat: 0.0 },
                  "fixed_price" => { hours: 0.0, turnover_excl_vat: 0.0, vat: 0.0, turnover_incl_vat: 0.0 },
                  "service" => { hours: 0.0, turnover_excl_vat: 0.0, vat: 0.0, turnover_incl_vat: 0.0 },
                  "training" => { hours: 0.0, turnover_excl_vat: 0.0, vat: 0.0, turnover_incl_vat: 0.0 },
                }
      
                iterated_users.each do |user_target, type, user, full_name, company_name, customer_name, broker_name, calculation_type, start_date, end_date, identification, hourtype, hours, rate, subrows, turnover_ex, vat, turnover_in, timesheet_id, projectuser_id, invoice, credit|
                  if target == user_target
                    if projectuser_id.blank?
                      customer_id   = nil
                      project_id    = nil
                      project_name  = nil
                    else
                      projectuser = Projectuser.find(projectuser_id)
                      customer_id   = projectuser.project.customer_id
                      project_id    = projectuser.project_id
                      project_name  = projectuser.project.name
                    end
      
                    target_id = targets.index(target)
                    uid = "#{year}#{month}#{target_id}#{year}#{month}#{account.id}#{company.id}#{user.id}#{customer_id}#{projectuser_id}#{hourtype}".to_i
      
                    # Set group based on calculation type and customer
                    if ["hour_based", "training"].include?(calculation_type)
                      if customer_name.blank? or customer_id.blank?
                        group = "training"
                      else
                        customer = Customer.find(customer_id)
                        group = customer.within_account ? "consultants_internal" : "consultants_external"
                      end
                    elsif ["fixed_price"].include?(calculation_type)
                      group = "fixed_price"
                    elsif ["service"].include?(calculation_type)
                      group = "service"
                    else
                      group = nil
                    end    
              
                    if type == "main"
                      hourtype_description = nil
                      total_hours += hours unless hours.blank?
                      total_turnover_excl_vat += turnover_ex unless turnover_ex.blank?
                      total_vat += vat unless vat.blank?
                      total_turnover_incl_vat += turnover_in unless turnover_in.blank?
      
                      group_totals[group][:hours] += hours unless hours.blank?
                      group_totals[group][:turnover_excl_vat] += turnover_ex unless turnover_ex.blank?
                      group_totals[group][:vat] += vat unless vat.blank?
                      group_totals[group][:turnover_incl_vat] += turnover_in unless turnover_in.blank?
                    else
                      hourtype_description = hourtype.blank? ? nil : Hourtype.find(hourtype).description
                    end

                    Dw::BbGroupedWorkOverview.upsert({ uid: uid, account_id: account.id, company_id: company.id, user_id: user.id, customer_id: customer_id, project_id: project_id, 
                      timesheet_id: timesheet_id, projectuser_id: projectuser_id, invoice_id: nil, month: month, year: year, account_name: account.name, company_name: company.name, target: target, 
                      group: group, row_type: type, user_name: user.full_name, show_name: nil, customer_name: customer_name, project_name: project_name, broker: broker_name, start_date: start_date, end_date: end_date, 
                      calculation_type: calculation_type, hour_type: hourtype_description, hours: hours, rate: rate, invoices: invoice, progress: nil, frequence: nil, type_amount: nil, 
                      period_amount: nil, credit: credit, status: nil, invoice_date: nil, turnover_excl_vat: turnover_ex, vat: vat, turnover_incl_vat: turnover_in}, unique_by: [:uid])
                  end
                end
      
                # Save target totals
                target_id = targets.index(target)
                uid = "#{target_id}#{account.id}#{company.id}#{month}#{year}".to_i

                Dw::BbGroupedWorkOverview.upsert({ uid: uid, account_id: account.id, company_id: company.id, user_id: nil, customer_id: nil, project_id: nil, 
                  timesheet_id: nil, projectuser_id: nil, invoice_id: nil, month: month, year: year, account_name: account.name, company_name: company.name, target: target, 
                  group: "total", row_type: "total", user_name: nil, show_name: nil, customer_name: nil, project_name: nil, broker: nil, start_date: nil, end_date: nil, 
                  calculation_type: nil, hour_type: nil, hours: total_hours, rate: nil, invoices: nil, progress: nil, frequence: nil, type_amount: nil, 
                  period_amount: nil, credit: nil, status: nil, invoice_date: nil, turnover_excl_vat: total_turnover_excl_vat, vat: total_vat, turnover_incl_vat: total_turnover_incl_vat}, unique_by: [:uid])
  
                # Save group totals
                group_totals.each_with_index do |(group, values), index|
                  group_id = index + 1
                  uid = "#{group_id}#{target_id}#{account.id}#{company.id}#{month}#{year}".to_i
      
                  Dw::BbGroupedWorkOverview.upsert({ uid: uid, account_id: account.id, company_id: company.id, user_id: nil, customer_id: nil, project_id: nil, 
                    timesheet_id: nil, projectuser_id: nil, invoice_id: nil, month: month, year: year, account_name: account.name, company_name: company.name, target: target, 
                    group: group, row_type: "total_group", user_name: nil, show_name: nil, customer_name: nil, project_name: nil, broker: nil, start_date: nil, end_date: nil, 
                    calculation_type: nil, hour_type: nil, hours: values[:hours], rate: nil, invoices: nil, progress: nil, frequence: nil, type_amount: nil, 
                    period_amount: nil, credit: nil, status: nil, invoice_date: nil, turnover_excl_vat: values[:turnover_excl_vat], vat: values[:vat], turnover_incl_vat: values[:turnover_incl_vat]}, unique_by: [:uid])
                end
              end
      
              if target == "services"
                target_id = targets.index(target)
      
                total_turnover_excl_vat = 0.0
                total_vat = 0.0
                total_turnover_incl_vat = 0.0
      
                iterated_services = ProjectsIterator.new(company.id).create_availability_iterations(month, year, "service")
                iterated_services.each do |project, project_id, customer_name, project_name, turnover_ex, vat, turnover_in, invoice_ids|
                  total_turnover_excl_vat += turnover_ex unless turnover_ex.blank?
                  total_vat += vat unless vat.blank?
                  total_turnover_incl_vat += turnover_in unless turnover_in.blank?
      
                  customer_id = project_id.blank? ? nil : project.customer_id
                  uid = "#{target_id}#{account.id}#{company.id}#{month}#{year}#{project_id}".to_i
      
                  Dw::BbGroupedWorkOverview.upsert({ uid: uid, account_id: account.id, company_id: company.id, user_id: nil, customer_id: customer_id, project_id: project_id, 
                    timesheet_id: nil, projectuser_id: nil, invoice_id: nil, month: month, year: year, account_name: account.name, company_name: company.name, target: target, 
                    group: nil, row_type: "main", user_name: nil, show_name: nil, customer_name: customer_name, project_name: project_name, broker: nil, start_date: nil, end_date: nil, 
                    calculation_type: nil, hour_type: nil, hours: nil, rate: nil, invoices: invoice_ids, progress: nil, frequence: nil, type_amount: nil, 
                    period_amount: nil, credit: nil, status: nil, invoice_date: nil, turnover_excl_vat: turnover_ex, vat: vat, turnover_incl_vat: turnover_in}, unique_by: [:uid])
                end
      
                uid = "#{target_id}#{account.id}#{company.id}#{month}#{year}".to_i
      
                Dw::BbGroupedWorkOverview.upsert({ uid: uid, account_id: account.id, company_id: company.id, user_id: nil, customer_id: nil, project_id: nil, 
                  timesheet_id: nil, projectuser_id: nil, invoice_id: nil, month: month, year: year, account_name: account.name, company_name: company.name, target: target, 
                  group: "total", row_type: "total", user_name: nil, show_name: nil, customer_name: nil, project_name: nil, broker: nil, start_date: nil, end_date: nil, 
                  calculation_type: nil, hour_type: nil, hours: nil, rate: nil, invoices: nil, progress: nil, frequence: nil, type_amount: nil, 
                  period_amount: nil, credit: nil, status: nil, invoice_date: nil, turnover_excl_vat: total_turnover_excl_vat, vat: total_vat, turnover_incl_vat: total_turnover_incl_vat}, unique_by: [:uid])
              end
      
              if target == "internally_charged"
                target_id = targets.index(target)
      
                total_hours = 0.0
                total_turnover_excl_vat = 0.0
                total_vat = 0.0
                total_turnover_incl_vat = 0.0
      
                iterated_internal_invoices = InvoicesIterator.new.create_availability_iterations(company.id, month, year, "internally_charged")
                iterated_internal_invoices.each do |invoice, invoice_id, status, contact_id, hours, turnover_ex, vat, turnover_in|
                  total_hours += hours unless hours.blank?
                  total_turnover_excl_vat += turnover_ex unless turnover_ex.blank?
                  total_vat += vat unless vat.blank?
                  total_turnover_incl_vat += turnover_in unless turnover_in.blank?
      
                  if contact_id.blank?
                    customer_id = nil
                    customer_name = nil
                  else
                    customer = Contact.find(contact_id).customer
                    customer_id = customer.id
                    customer_name = customer.name
                  end
      
                  uid = "#{target_id}#{account.id}#{company.id}#{month}#{year}#{invoice_id}".to_i
      
                  Dw::BbGroupedWorkOverview.upsert({ uid: uid, account_id: account.id, company_id: company.id, user_id: nil, customer_id: customer_id, project_id: nil, 
                    timesheet_id: nil, projectuser_id: nil, invoice_id: invoice_id, month: month, year: year, account_name: account.name, company_name: company.name, target: target, 
                    group: nil, row_type: "main", user_name: nil, show_name: nil, customer_name: customer_name, project_name: nil, broker: nil, start_date: nil, end_date: nil, 
                    calculation_type: nil, hour_type: nil, hours: hours, rate: nil, invoices: nil, progress: nil, frequence: nil, type_amount: nil, 
                    period_amount: nil, credit: nil, status: invoice.status, invoice_date: invoice.invoice_date, turnover_excl_vat: turnover_ex, vat: vat, turnover_incl_vat: turnover_in}, unique_by: [:uid])
                end

                uid = "#{target_id}#{account.id}#{company.id}#{month}#{year}".to_i
            
                Dw::BbGroupedWorkOverview.upsert({ uid: uid, account_id: account.id, company_id: company.id, user_id: nil, customer_id: nil, project_id: nil, 
                  timesheet_id: nil, projectuser_id: nil, invoice_id: nil, month: month, year: year, account_name: account.name, company_name: company.name, target: target, 
                  group: "total", row_type: "total", user_name: nil, show_name: nil, customer_name: nil, project_name: nil, broker: nil, start_date: nil, end_date: nil, 
                  calculation_type: nil, hour_type: nil, hours: total_hours, rate: nil, invoices: nil, progress: nil, frequence: nil, type_amount: nil, 
                  period_amount: nil, credit: nil, status: nil, invoice_date: nil, turnover_excl_vat: total_turnover_excl_vat, vat: total_vat, turnover_incl_vat: total_turnover_incl_vat}, unique_by: [:uid])
              end
      
              if target == "projects"
                target_id = targets.index(target)
      
                total_turnover_excl_vat = 0.0
                total_vat = 0.0
                total_turnover_incl_vat = 0.0
      
                iterated_projects = ProjectsIterator.new(company.id).create_availability_iterations(month, year, "fixed_price")
                iterated_projects.each do |project, project_id, customer_name, project_name, turnover_ex, vat, turnover_in, invoice_ids|
                  total_turnover_excl_vat += turnover_ex unless turnover_ex.blank?
                  total_vat += vat unless vat.blank?
                  total_turnover_incl_vat += turnover_in unless turnover_in.blank?
      
                  customer_id = project_id.blank? ? nil : project.customer_id
                  uid = "#{target_id}#{account.id}#{company.id}#{month}#{year}#{project_id}".to_i
      
                  Dw::BbGroupedWorkOverview.upsert({ uid: uid, account_id: account.id, company_id: company.id, user_id: nil, customer_id: customer_id, project_id: project_id, 
                    timesheet_id: nil, projectuser_id: nil, invoice_id: nil, month: month, year: year, account_name: account.name, company_name: company.name, target: target, 
                    group: nil, row_type: "main", user_name: nil, show_name: nil, customer_name: customer_name, project_name: project_name, broker: nil, start_date: nil, end_date: nil, 
                    calculation_type: nil, hour_type: nil, hours: nil, rate: nil, invoices: invoice_ids, progress: nil, frequence: nil, type_amount: nil, 
                    period_amount: nil, credit: nil, status: nil, invoice_date: nil, turnover_excl_vat: turnover_ex, vat: vat, turnover_incl_vat: turnover_in}, unique_by: [:uid])
                end
      
                uid = "#{target_id}#{account.id}#{company.id}#{month}#{year}".to_i
      
                Dw::BbGroupedWorkOverview.upsert({ uid: uid, account_id: account.id, company_id: company.id, user_id: nil, customer_id: nil, project_id: nil, 
                  timesheet_id: nil, projectuser_id: nil, invoice_id: nil, month: month, year: year, account_name: account.name, company_name: company.name, target: target, 
                  group: "total", row_type: "total", user_name: nil, show_name: nil, customer_name: nil, project_name: nil, broker: nil, start_date: nil, end_date: nil, 
                  calculation_type: nil, hour_type: nil, hours: nil, rate: nil, invoices: nil, progress: nil, frequence: nil, type_amount: nil, 
                  period_amount: nil, credit: nil, status: nil, invoice_date: nil, turnover_excl_vat: total_turnover_excl_vat, vat: total_vat, turnover_incl_vat: total_turnover_incl_vat}, unique_by: [:uid])
              end
      
              if target == "trainings"
                target_id = targets.index(target)
      
                total_turnover_excl_vat = 0.0
                total_vat = 0.0
                total_turnover_incl_vat = 0.0
      
                iterated_trainings = ProjectsIterator.new(company.id).create_availability_iterations(month, year, "training")
                iterated_trainings.each do |project, project_id, customer_name, project_name, turnover_ex, vat, turnover_in, invoice_ids|
                  total_turnover_excl_vat += turnover_ex unless turnover_ex.blank?
                  total_vat += vat unless vat.blank?
                  total_turnover_incl_vat += turnover_in unless turnover_in.blank?
      
                  customer_id = project_id.blank? ? nil : project.customer_id
                  uid = "#{target_id}#{account.id}#{company.id}#{month}#{year}#{project_id}".to_i
      
                  Dw::BbGroupedWorkOverview.upsert({ uid: uid, account_id: account.id, company_id: company.id, user_id: nil, customer_id: customer_id, project_id: project_id, 
                    timesheet_id: nil, projectuser_id: nil, invoice_id: nil, month: month, year: year, account_name: account.name, company_name: company.name, target: target, 
                    group: nil, row_type: "main", user_name: nil, show_name: nil, customer_name: customer_name, project_name: project_name, broker: nil, start_date: nil, end_date: nil, 
                    calculation_type: nil, hour_type: nil, hours: nil, rate: nil, invoices: invoice_ids, progress: nil, frequence: nil, type_amount: nil, 
                    period_amount: nil, credit: nil, status: nil, invoice_date: nil, turnover_excl_vat: turnover_ex, vat: vat, turnover_incl_vat: turnover_in}, unique_by: [:uid])
                end
      
                uid = "#{target_id}#{account.id}#{company.id}#{month}#{year}".to_i
      
                Dw::BbGroupedWorkOverview.upsert({ uid: uid, account_id: account.id, company_id: company.id, user_id: nil, customer_id: nil, project_id: nil, 
                  timesheet_id: nil, projectuser_id: nil, invoice_id: nil, month: month, year: year, account_name: account.name, company_name: company.name, target: target, 
                  group: "total", row_type: "total", user_name: nil, show_name: nil, customer_name: nil, project_name: nil, broker: nil, start_date: nil, end_date: nil, 
                  calculation_type: nil, hour_type: nil, hours: nil, rate: nil, invoices: nil, progress: nil, frequence: nil, type_amount: nil, 
                  period_amount: nil, credit: nil, status: nil, invoice_date: nil, turnover_excl_vat: total_turnover_excl_vat, vat: total_vat, turnover_incl_vat: total_turnover_incl_vat}, unique_by: [:uid])
              end

              if target == "consolidated_invoices"
                target_id = targets.index(target)
      
                total_hours = 0.0
                total_turnover_excl_vat = 0.0
                total_vat = 0.0
                total_turnover_incl_vat = 0.0
      
                iterated_invoices = InvoicesIterator.new.create_availability_iterations(company.id, month, year)
                iterated_invoices.each do |invoice, invoice_id, status, contact_id, hours, turnover_ex, vat, turnover_in|
                  unless invoice.consolidated_invoice_code.blank?
                    total_hours += hours unless hours.blank?
                    total_turnover_excl_vat += turnover_ex unless turnover_ex.blank?
                    total_vat += vat unless vat.blank?
                    total_turnover_incl_vat += turnover_in unless turnover_in.blank?
        
                    if contact_id.blank?
                      customer_id = nil
                      customer_name = nil
                    else
                      customer = Contact.find(contact_id).customer
                      customer_id = customer.id
                      customer_name = customer.name
                    end
        
                    uid = "#{target_id}#{account.id}#{company.id}#{month}#{year}#{invoice_id}".to_i
        
                    Dw::BbGroupedWorkOverview.upsert({ uid: uid, account_id: account.id, company_id: company.id, user_id: nil, customer_id: customer_id, project_id: nil, 
                      timesheet_id: nil, projectuser_id: nil, invoice_id: invoice_id, month: month, year: year, account_name: account.name, company_name: company.name, target: target, 
                      group: nil, row_type: "main", user_name: nil, show_name: nil, customer_name: customer_name, project_name: nil, broker: nil, start_date: nil, end_date: nil, 
                      calculation_type: nil, hour_type: nil, hours: hours, rate: nil, invoices: nil, progress: nil, frequence: nil, type_amount: nil, 
                      period_amount: nil, credit: nil, status: invoice.status, invoice_date: invoice.invoice_date, turnover_excl_vat: turnover_ex, vat: vat, turnover_incl_vat: turnover_in}, unique_by: [:uid])
                  end
                end
      
                uid = "#{target_id}#{account.id}#{company.id}#{month}#{year}".to_i
      
                Dw::BbGroupedWorkOverview.upsert({ uid: uid, account_id: account.id, company_id: company.id, user_id: nil, customer_id: nil, project_id: nil, 
                  timesheet_id: nil, projectuser_id: nil, invoice_id: nil, month: month, year: year, account_name: account.name, company_name: company.name, target: target, 
                  group: "total", row_type: "total", user_name: nil, show_name: nil, customer_name: nil, project_name: nil, broker: nil, start_date: nil, end_date: nil, 
                  calculation_type: nil, hour_type: nil, hours: total_hours, rate: nil, invoices: nil, progress: nil, frequence: nil, type_amount: nil, 
                  period_amount: nil, credit: nil, status: nil, invoice_date: nil, turnover_excl_vat: total_turnover_excl_vat, vat: total_vat, turnover_incl_vat: total_turnover_incl_vat}, unique_by: [:uid])
              end

              if target == "invoices"
                target_id = targets.index(target)
      
                total_hours = 0.0
                total_turnover_excl_vat = 0.0
                total_vat = 0.0
                total_turnover_incl_vat = 0.0
      
                iterated_invoices = InvoicesIterator.new.create_availability_iterations(company.id, month, year)
                iterated_invoices.each do |invoice, invoice_id, status, contact_id, hours, turnover_ex, vat, turnover_in|
                  if invoice.consolidated_invoice_code.blank?
                    total_hours += hours unless hours.blank?
                    total_turnover_excl_vat += turnover_ex unless turnover_ex.blank?
                    total_vat += vat unless vat.blank?
                    total_turnover_incl_vat += turnover_in unless turnover_in.blank?
        
                    if contact_id.blank?
                      customer_id = nil
                      customer_name = nil
                    else
                      customer = Contact.find(contact_id).customer
                      customer_id = customer.id
                      customer_name = customer.name
                    end
        
                    uid = "#{target_id}#{account.id}#{company.id}#{month}#{year}#{invoice_id}".to_i
        
                    Dw::BbGroupedWorkOverview.upsert({ uid: uid, account_id: account.id, company_id: company.id, user_id: nil, customer_id: customer_id, project_id: nil, 
                      timesheet_id: nil, projectuser_id: nil, invoice_id: invoice_id, month: month, year: year, account_name: account.name, company_name: company.name, target: target, 
                      group: nil, row_type: "main", user_name: nil, show_name: nil, customer_name: customer_name, project_name: nil, broker: nil, start_date: nil, end_date: nil, 
                      calculation_type: nil, hour_type: nil, hours: hours, rate: nil, invoices: nil, progress: nil, frequence: nil, type_amount: nil, 
                      period_amount: nil, credit: nil, status: invoice.status, invoice_date: invoice.invoice_date, turnover_excl_vat: turnover_ex, vat: vat, turnover_incl_vat: turnover_in}, unique_by: [:uid])
                  end
                end
      
                uid = "#{target_id}#{account.id}#{company.id}#{month}#{year}".to_i
      
                Dw::BbGroupedWorkOverview.upsert({ uid: uid, account_id: account.id, company_id: company.id, user_id: nil, customer_id: nil, project_id: nil, 
                  timesheet_id: nil, projectuser_id: nil, invoice_id: nil, month: month, year: year, account_name: account.name, company_name: company.name, target: target, 
                  group: "total", row_type: "total", user_name: nil, show_name: nil, customer_name: nil, project_name: nil, broker: nil, start_date: nil, end_date: nil, 
                  calculation_type: nil, hour_type: nil, hours: total_hours, rate: nil, invoices: nil, progress: nil, frequence: nil, type_amount: nil, 
                  period_amount: nil, credit: nil, status: nil, invoice_date: nil, turnover_excl_vat: total_turnover_excl_vat, vat: total_vat, turnover_incl_vat: total_turnover_incl_vat}, unique_by: [:uid])
              end
            end
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