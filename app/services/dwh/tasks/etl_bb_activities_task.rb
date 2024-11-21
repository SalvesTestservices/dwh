class Dwh::Tasks::EtlBbActivitiesTask < Dwh::Tasks::BaseTask
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
      # Extract activtities
      ActsAsTenant.without_tenant do
        account         = Account.find(run.account_id)
        dp_pipeline     = run.dp_pipeline
        year            = run.dp_pipeline.year.blank? ? Date.current.year : run.dp_pipeline.year.to_i
        month           = run.dp_pipeline.month.blank? ? Date.current.month : run.dp_pipeline.month.to_i
        previous_month  = Date.new(year, month, 1).prev_month

        # Skip old companies
        users = account.users.where.not(company_id: get_excluded_company_ids)

        # Exclude roles
        users = users.where.not(role: get_excluded_roles)

        # Exclude Rense Boonstra
        users = users.where.not(id: 29)

        # Scope users 
        if dp_pipeline.scoped_user_id.present?
          users = users.where(id: dp_pipeline.scoped_user_id.to_i)
        end
        
        timesheets = account.timesheets.where(status: "approved", year: previous_month.year, month: previous_month.month, user_id: users.pluck(:id))        
        unless timesheets.blank?
          timesheets.each do |timesheet|
            unless timesheet.activities.blank?
              timesheet.activities.each do |activity|
                activity_hash = Hash.new

                if activity.projectuser_id.blank? or activity.projectuser.blank? or activity.projectuser.project.blank?
                  customer_id = nil
                else
                  customer_id = activity.projectuser.project.customer_id
                end

                if activity.projectuser_id.blank? or activity.projectuser.blank?
                  project_id = nil
                else
                  project_id = activity.projectuser.project_id
                end

                if activity.original_rate.blank?
                  rate = 0
                elsif activity.original_rate > 200
                  rate = activity.original_rate / 8.0
                else
                  rate = activity.original_rate
                end

                activity_hash[:original_id]     = activity.id
                activity_hash[:customer_id]     = customer_id
                activity_hash[:unbillable_id]   = activity.unbillable_id
                activity_hash[:user_id]         = timesheet.user_id
                activity_hash[:company_id]      = timesheet.user.company_id
                activity_hash[:projectuser_id]  = activity.projectuser_id
                activity_hash[:project_id]      = project_id
                activity_hash[:activity_date]   = Date.new(timesheet.year, timesheet.month, activity.day).strftime("%d%m%Y").to_i
                activity_hash[:hours]           = activity.hours
                activity_hash[:rate]            = rate

                Dwh::EtlStorage.create(account_id: account.id, identifier: "activities", etl: "transform", data: activity_hash)
              end
            end
          end
        end

        # Load activities
        Dwh::Loaders::ActivitiesLoader.new.load_data(account)
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
