class Dwh::Tasks::EtlExactActivitiesBackboneRwsTask < Dwh::Tasks::BaseExactTask
  queue_as :default

  def perform(task_account_id, task_account_name, run, result, task)
    # Wait for alle dependencies to finish
    all_dependencies_finished = wait_on_dependencies(task_account_name, run, task)
    if all_dependencies_finished == false
      Dwh::DataPipelineLogger.new.create_log(run.id, "cancelled", "[#{task_account_name}] Taak [#{task.task_key}] geannuleerd")
      result.update(finished_at: DateTime.now, status: "cancelled")
      return
    end

    begin
      account = Account.find(task_account_id)
      api_url, api_key, administration = get_api_keys("synergy")

      # Cancel the task if the API keys are not valid
      if api_url.blank? or api_key.blank? or administration.blank?
        Dwh::DataPipelineLogger.new.create_log(run.id, "alert", "[#{account.name}] Invalid API keys")
        result.update(finished_at: DateTime.now, status: "error")
        return  
      end

      # Get customer RWS from dim_customers
      rws = Dwh::DimCustomer.find_by(account_id: account.id, name "Rijkswaterstaat")

      # Get all RWS activities created or updated in the last 24 hours from fact_activities
      dim_date = Dwh::DimDate.find_by(Date.today - 1.day)
      activities = Dwh::FactActivity.where(account_id: account.id, customer_id: rws.id, activity_date: dim_date.id)
      unless activities.blank?
        activities.each do |activity|
          # Write or update activities in Backbone
        end
      end

    

      # Update result
      result.update(finished_at: DateTime.now, status: "finished")
      Dwh::DataPipelineLogger.new.create_log(run.id, "success", "[#{task_account_name}] Finished task [#{task.task_key}] successfully")
    rescue => e
      # Update result to failed if an error occurs
      result.update(finished_at: DateTime.now, status: "failed", error: e.message)
      Dwh::DataPipelineLogger.new.create_log(run.id, "alert", "[#{task_account_name}] Finished task [#{task.task_key}] with error: #{e.message}")
    end
  end
end