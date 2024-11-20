class Dw::Tasks::BbTimesheetHoursOverviewTask < Dw::Tasks::BaseTask
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
        year  = run.dp_pipeline.year.blank? ? 1.month.ago.year : run.dp_pipeline.year.to_i
        month = run.dp_pipeline.month.blank? ? 1.month.ago.month : run.dp_pipeline.month.to_i

        companies = account.companies.active.where.not(id: [8, 2, 48])
        companies.each do |company|
          company.users.each do |user|
            timesheets = user.timesheets.where(year: year, month: month, status: "approved")
            unless timesheets.blank?
              timesheets.each do |timesheet|
                activities = timesheet.activities.order(:day)
                unless activities.blank?
                  activities.each do |activity|
                    if activity.unbillable_id.blank?
                      projectuser = Projectuser.find(activity.projectuser_id)
                      project_name = projectuser.project.name

                      if projectuser.project.blank? or projectuser.project.customer.blank?
                        customer_id = nil
                        customer_name = nil
                      else
                        customer = projectuser.project.customer
                        customer_id = customer.id
                        customer_name = customer.name
                      end

                      unbillable_id   = nil
                      unbillable_name = nil

                      if user.external?
                        purchase_price = RateCalculator.new(activity).calculate_rate("purchase_price", Date.new(timesheet.year, timesheet.month, activity.day))
                      else
                        purchase_price = nil
                      end
                    else
                      unbillable      = Unbillable.find(activity.unbillable_id)
                      unbillable_id   = unbillable.id
                      unbillable_name = unbillable.name
                      customer_id     = nil
                      customer_name   = nil
                      project_name    = nil
                      purchase_price  = nil
                    end
  
                    uid = activity.id

                    Dw::BbTimesheetHourOverview.upsert({ uid: uid, day: activity.day, month: timesheet.month, year: timesheet.year, account_id: account.id, company_id: company.id, user_id: user.id, 
                      customer_id: customer_id, unbillable_id: unbillable_id, account_name: account.name, company_name: company.name, user_name: user.full_name, customer_name: customer_name, 
                      project_name: project_name, unbillable_name: unbillable_name, hours: activity.hours, rate: activity.original_rate, purchase_price: purchase_price}, unique_by: [:uid])
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
    rescue => e
      # Update result to failed if an error occurs
      result.update(finished_at: DateTime.now, status: "failed", error: e.message)
      Dw::DataPipelineLogger.new.create_log(run.id, "alert", "[#{account.name}] Finished task [#{task.task_key}] with error: #{e.message}")
    end
  end
end