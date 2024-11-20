class Dw::Tasks::BbRwsOhwOverviewTask < Dw::Tasks::BaseTask
  queue_as :default

  def perform(account, run, result, task)
    # Wait for alle dependencies to finish
    all_dependencies_finished = wait_on_dependencies(account, run, task)
    if all_dependencies_finished == false
      Dw::DataPipelineLogger.new.create_log(run.id, "cancelled", "[#{account.name}] Taak [#{task.task_key}] geannuleerd")
      result.update(finished_at: DateTime.now, status: "cancelled")
      return
    end

    #begin
      ActsAsTenant.without_tenant do
        offers = account.offers
        unless offers.blank?
          approved_project_ids = nil
          project_ids = offers.pluck(:project_id)
          projects = account.projects.includes(:customer).includes(:company).includes(:projectusers).includes(:offer).where("projects.id IN (?) or projects.id IN (?)", project_ids, approved_project_ids).order("offers.year, offers.offer_nr_counter")
    
          # Init projects totals by defining total range
          month_totals = Array.new
          offer_ids = account.offers.where("project_id IN (?)", projects.pluck(:id)).pluck(:id)
          offer_deliverables = account.deliverables.where("offer_id IN (?)", offer_ids).active
          preliminary_ids = offer_deliverables.where(preliminary: true).pluck(:preliminary_id)
          if preliminary_ids.blank?
            range_deliverables = offer_deliverables.where(preliminary: false)
          else
            range_deliverables = offer_deliverables.where("preliminary = true OR (preliminary = false AND id NOT IN (?))", preliminary_ids)
          end
      
          # Determine first and last deliverable
          first_deliverable = range_deliverables.where("start_date IS NOT NULL").order(:start_date, :end_date, :delivery_date).first
          last_deliverable = range_deliverables.where("end_date IS NOT NULL").order(:end_date, :end_date, :delivery_date).last
      
          # Determine range
          start_period = first_deliverable.start_date.blank? ? Date.current.beginning_of_month : first_deliverable.start_date.beginning_of_month
          end_period = last_deliverable.end_date.blank? ? Date.current.beginning_of_month : last_deliverable.end_date.beginning_of_month
      
          range = (start_period..end_period).select {|d| d.day == 1}
          range.map do |month_date|
            month = month_date.month
            year = month_date.year
            month_totals << [year, month, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
          end
      
          # Iterate all projects
          unless projects.blank?
            projects.each do |project|
              # Project data
              offer = account.offers.find_by(project_id: project.id)

              case offer.order_status
              when "new"
                status = I18n.t('.offer.states.new')
              when "offered"
                status = I18n.t('.offer.states.offered')
              when "pushed"
                status = I18n.t('.offer.states.pushed')
              when "provided"
                status = I18n.t('.offer.states.provided')
              when "despatched"
                status = I18n.t('.offer.states.despatched')
              when "approved_internal"
                status = I18n.t('.offer.states.approved_internal')
              when "disapproved_internal"
                status = I18n.t('.offer.states.disapproved_internal')
              when "approved"
                status = I18n.t('.offer.states.approved')
              when "disapproved"
                status = I18n.t('.offer.states.disapproved')
              when "cancelled"
                status = I18n.t('.offer.states.cancelled')
              when "finished"
                status = I18n.t('.offer.states.finished')
              when "invoiced"
                status = I18n.t('.offer.states.invoiced')
              end

              project_deliverables = project.offer.deliverables.active.where("status != 'expired' OR (status = 'expired' and name = 'Correctie tbv boekhouding')")
              preliminary_ids = project_deliverables.where(preliminary: true).pluck(:preliminary_id)
              if preliminary_ids.blank?
                deliverables = project_deliverables.order(:start_date, :id)
              else
                deliverables = project_deliverables.where("preliminary = true OR (preliminary = false AND id NOT IN (?))", preliminary_ids)
              end
    
              # Determine first date by adding all dates from deliverables and proformas
              first_dates = Array.new
              proforma_ids = account.proformalines.where("deliverable_id IN (?)", deliverables.pluck(:id)).pluck(:proforma_id)
              proformas = account.proformas.where("id IN (?)", proforma_ids)
              unless proformas.blank?
                proformas.each do |proforma|
                  first_dates << Date.new(proforma.year, proforma.month,1)
                end
              end
    
              deliverables.each do |deliverable|
                first_dates << deliverable.start_date
              end

              unless first_dates.blank?
                # Sort and determine end period
                first_dates = first_dates.sort
                start_period = Date.new(first_dates.first.year, first_dates.first.month, 1)
          
                # Determine last date by adding all dates from deliverables and proformas
                last_dates = Array.new
                deliverables.each do |deliverable|
                  # If the deliverable has a parent stelpost deliverable which is not ready, then
                  # automatically add 1 month to end date
                  continue_setting_end_date = true
                  if deliverable.preliminary_id.present?
                    preliminary_deliverable = account.deliverables.find(deliverable.preliminary_id)
                    if preliminary_deliverable.present? and preliminary_deliverable.status != "ready" and preliminary_deliverable.status != "expired"
                      last_dates << Date.current
                      continue_setting_end_date = false
                    end
                  end
      
                  # There is no preliminary deliverable, so set end date based on proforma or deliverable itself
                  if continue_setting_end_date == true
                    proformaline = account.proformalines.find_by("deliverable_id = ?", deliverable.id)
                    proforma = account.proformas.find_by(id: proformaline.proforma_id) unless proformaline.blank?
                    if deliverable.id != 2074 and proformaline.present? and proforma.present?
                      last_dates << Date.new(proforma.year, proforma.month,1)
                    else
                      if deliverable.delivery_date.present?
                        last_dates << deliverable.delivery_date
                      else
                        last_dates << deliverable.end_date
                      end
                    end
                  end
                end
      
                # Sort and determine end period
                last_dates = last_dates.sort
                end_period = Date.new(last_dates.last.year, last_dates.last.month, 1)
          
                # Set range
                range = (start_period..end_period).select {|d| d.day == 1}
                range.map do |month_date|
                  month = month_date.month
                  year = month_date.year
      
                  month_purchasing_total = 0.0
                  month_users_total = 0.0
      
                  # Get hours for month
                  projectusers = project.projectusers
                  unless projectusers.blank?
                    users_total = 0.0
                    projectusers.each do |projectuser|
                      user = projectuser.user
                      timesheet = user.timesheets.find_by_month_and_year(month, year)
                      timesheet_hours = timesheet.blank? ? 0 : TimesheetCalculator.new(timesheet).get_registered_project_hours(projectuser.id)
                      hours = timesheet_hours unless timesheet_hours.blank?
      
                      # Calculate rate
                      rate_calculator = RateCalculator.new(nil, projectuser)
      
                      if projectuser.user.external?
                        rate = rate_calculator.calculate_rate("purchase_price")
                      else
                        rate = rate_calculator.calculate_rate("internal_rate")
                        if rate == 0.0
                          rate = rate_calculator.calculate_rate("rate")
                        end
                      end
                      rate = rate.blank? ? 0.0 : rate
                      total = (hours*rate).round(2)
                      users_total += total
      
                      uid = "#{account.id}#{offer.id}#{year}#{month}#{project.id}#{projectuser.id}#{user.id}"

                      Dw::BbRwsOhwOverview.upsert({ uid: uid, account_id: account.id, year: year, month: month, offer_id: offer.id, 
                        offer_nr: offer.offer_nr, status: status, deliverable_name: nil, invoice_nr_purchasing: nil, amount_purchasing: nil, 
                        invoice_nr_sales: nil, invoice_date_sales: nil, amount_sales: nil, employee_name: user.full_name, hours: hours, 
                        rate: rate, total_employee: total}, unique_by: [:uid])
                    end
                  end
                  month_users_total += users_total unless users_total.blank?
      
                  # Get all deliverables for this month
                  month_proformas = account.proformas.where("year = ? AND month = ?", year, month)
                  month_proformalines = account.proformalines.where("deliverable_id IN (?) AND proforma_id IN (?) AND status = 'approved_level2'", deliverables.pluck(:id), month_proformas.pluck(:id))
                  month_deliverables = deliverables.where("id IN (?)", month_proformalines.pluck(:deliverable_id))
                  
                  unless month_deliverables.blank?
                    month_deliverables.each do |deliverable|
                      # Purchasing costs
                      amount_purchasing = 0.0
                      amount_sales = 0.0
                      proformaline = account.proformalines.find_by(deliverable_id: deliverable.id, status: "approved_level2")
                      if proformaline.present? and proformaline.proforma.month == month and proformaline.proforma.year == year
                        amount_purchasing += deliverable.purchase_price unless deliverable.purchase_price.blank?
                        amount_sales += deliverable.price unless deliverable.price.blank?
      
                        if proformaline.invoice_id.present?
                          if proformaline.invoice.present? and proformaline.invoice.invoice_nr.present?
                            invoice_nr = proformaline.invoice.invoice_nr
                            invoice_date = proformaline.invoice.invoice_date
                          else
                            invoice_nr = nil
                            invoice_date = nil
                          end
                        end
                      else
                        invoice_nr = nil
                        invoice_date = nil
                      end

                      uid = "#{account.id}#{offer.id}#{year}#{month}#{deliverable.id}"

                      Dw::BbRwsOhwOverview.upsert({ uid: uid, account_id: account.id, year: year, month: month, offer_id: offer.id, 
                        offer_nr: offer.offer_nr, status: status, deliverable_name: deliverable.name, invoice_nr_purchasing: deliverable.purchase_invoice_reference, 
                        amount_purchasing: amount_purchasing, invoice_nr_sales: invoice_nr, invoice_date_sales: invoice_date, amount_sales: amount_sales, 
                        employee_name: nil, hours: nil, rate: nil, total_employee: users_total}, unique_by: [:uid])
                    end
                  end
                end
              end
            end
          end
        end
      end

      # Update result
      result.update(finished_at: DateTime.now, status: "finished")
      Dw::DataPipelineLogger.new.create_log(run.id, "success", "[#{account.name}] Finished task [#{task.task_key}] successfully")
    #rescue => e
    #  # Update result to failed if an error occurs
    #  result.update(finished_at: DateTime.now, status: "failed", error: e.message)
    #  Dw::DataPipelineLogger.new.create_log(run.id, "alert", "[#{account.name}] Finished task [#{task.task_key}] with error: #{e.message}")
    #end
  end
end
