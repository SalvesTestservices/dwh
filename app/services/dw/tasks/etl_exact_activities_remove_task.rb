class Dwh::Tasks::EtlExactActivitiesRemoveTask < Dwh::Tasks::BaseExactTask
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
        account              = Account.find(run.account_id)
        dim_account          = Dwh::DimAccount.find_by(original_id: account.id)
        previous_month_start = Date.new(Date.current.year, Date.current.month, 1).prev_month
        previous_month_end   = Date.new(Date.current.year, Date.current.month, -1).prev_month

        # Cancel the task if the API keys are not valid
        api_url, api_key, administration = get_api_keys("synergy")
        if api_url.blank? or api_key.blank? or administration.blank?
          Dwh::DataPipelineLogger.new.create_log(run.id, "alert", "[#{account.name}] Invalid API keys")
          result.update(finished_at: DateTime.now, status: "error")
          return  
        end

        # Set refreshed of all activities of the month to 0
        fact_activities = Dwh::FactActivity.where(account_id: dim_account.id).where("CAST(activity_date AS VARCHAR) LIKE ?", "%#{previous_month_start.strftime("%m%Y")}%")
        fact_activities.update_all(refreshed: 0)

        # Iterate all users
        dim_users = Dwh::DimUser.where(account_id: dim_account.id)
        unless dim_users.blank?
          dim_users.each do |dim_user|
            # Get all billable activities for user as long as the SkipToken is not empty (pagination)
            next_request = true
            skip_token = nil
            while next_request == true
              skip_token = skip_token.blank? ? nil : "&SkipToken=#{skip_token}"
              activities = send_get_request(api_url, api_key, administration, "Synergy/RequestListFiltered?filter=RequestType eq 9050 and ResourceID eq #{dim_user.original_id} and StartDate ge DateTime'#{previous_month_start.strftime("%Y-%m-%d")}' and StartDate le DateTime'#{previous_month_end.strftime("%Y-%m-%d")}'#{skip_token}")

              # Set the next request
              if activities == "CONNECTION ERROR"
                next_request = true
              elsif activities["SkipToken"] == "" or activities["SkipToken"].blank?
                next_request = false
                skip_token = nil
              else
                next_request = true
                skip_token = activities["SkipToken"]
              end

              # Iterate activities
              unless activities["Results"].blank?
                activities["Results"].each do |activity|
                  # Set refreshed to 1 for existing Synergy activity
                  fact_activity = fact_activities.find_by(original_id: activity["RequestID"])
                  fact_activity.update(refreshed: 1) unless fact_activity.blank?
                end
              end
            end

            # Iterate all unbillables
            dim_unbillables = Dwh::DimUnbillable.where(account_id: dim_account.id).where.not(original_id: ["LEEGLOOP", "INTERN", "ZIEK_GED_HERST"])
            unless dim_unbillables.blank?
              dim_unbillables.each do |dim_unbillable|
                # Get all unbillable activities as long as the SkipToken is not empty (pagination)
                request_type = dim_unbillable.original_id
                next_request = true
                skip_token = nil

                while next_request == true
                  skip_token = skip_token.blank? ? nil : "&SkipToken=#{skip_token}"
                  activities = send_get_request(api_url, api_key, administration, "Synergy/RequestListFiltered?filter=RequestType eq #{request_type} and ResourceID eq #{dim_user.original_id} and StartDate ge DateTime'#{previous_month_start}' and StartDate le DateTime'#{previous_month_end}'#{skip_token}")

                  # Set the next request
                  if activities == "CONNECTION ERROR"
                    next_request = true
                  elsif activities["SkipToken"] == "" or activities["SkipToken"].blank?
                    next_request = false
                    skip_token = nil
                  else
                    next_request = true
                    skip_token = activities["SkipToken"]
                  end

                  # Iterate activities
                  unless activities["Results"].blank?
                    activities["Results"].each do |activity|
                      # Set refreshed to 1 for existing Synergy activity
                      fact_activity = fact_activities.find_by(original_id: activity["RequestID"])
                      fact_activity.update(refreshed: 1) unless fact_activity.blank?
                    end
                  end
                end
              end
            end
          end
        end

        # Remove all activities that are not refreshed
        fact_activities.where(refreshed: 0).destroy_all

        # Set refreshed back to empty
        fact_activities.where.not(refreshed: nil).update_all(refreshed: nil)
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
