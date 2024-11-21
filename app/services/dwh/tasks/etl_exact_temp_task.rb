class Dwh::Tasks::EtlExactTempTask < Dwh::Tasks::BaseExactTask
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
      # Extract users
      ActsAsTenant.without_tenant do
        account     = Account.find(run.account_id)
        dim_account = Dwh::DimAccount.find_by(original_id: account.id)

        api_url, api_key, administration = get_api_keys("synergy")

        # Cancel the task if the API keys are not valid
        if api_url.blank? or api_key.blank? or administration.blank?
          Dwh::DataPipelineLogger.new.create_log(run.id, "alert", "[#{account.name}] Invalid API keys")
          result.update(finished_at: DateTime.now, status: "error")
          return  
        end

        # Update leave_date of dim_users
        dim_users = Dwh::DimUser.where(account_id: dim_account.id)
        dim_users.each do |dim_user|
          if dim_user.original_id == "424"
            dim_user.destroy
          else
            start_date, end_date = get_employment_dates(api_url, api_key, administration, dim_user.original_id)
            dim_user.update(leave_date: end_date)
          end
        end

        # Remove fixed price projects
        #dim_projects = Dwh::DimProject.where(account_id: dim_account.id, calculation_type: "fixed_price")
        #dim_projects.each do |dim_project|
        #  fact_projectusers = Dwh::FactProjectuser.where(project_id: dim_project.id)
        #  fact_projectusers.each do |fact_projectuser|
        #    fact_activities = Dwh::FactActivity.where(projectuser_id: fact_projectuser.id, project_id: dim_project.id).destroy_all
        #    fact_projectuser.destroy
        #  end
        #  dim_project.destroy
        #end
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

  private def get_employment_dates(api_url, api_key, administration, user_id)
    start_date = nil
    end_date = nil

    # First get a verification code
    query = "SELECT absences.ID AS ID, absences.HID AS HID, absences.EmpID as EmployeeID, absences.FreeTextField_01 AS Type, absences.FreeTextField_15 AS TypeDesc, absences.startdate AS StartDate, absences.enddate AS EndDate, absences.Description AS Description FROM absences WHERE absences.Type=11001 AND absences.EmpID=#{user_id} ORDER BY Absences.EmpID, absences.FreeTextField_15,absences.startdate,absences.HID"    
    body = send_custom_query(api_url, api_key, administration, "", query)

    # When there are no errors, then the verification code can be used to get the data
    if body["Errors"].blank?
      body = send_custom_query(api_url, api_key, administration, "#{body["VerificationCode"]}", query)

      # Iterate over the results and get the sales price of the valid item
      if body["Errors"].blank? and body["Results"].any?
        # Sort the results by StartDate
        sorted_results = body["Results"].sort_by { |result| result["StartDate"] }

        # Get the StartDate of the first result and the EndDate of the last result
        start_date = sorted_results.first["StartDate"]
        end_date = sorted_results.last["EndDate"]

        # Convert the dates to the correct format
        start_date = start_date.blank? ? nil : start_date.to_date.strftime("%d%m%Y").to_i
        end_date = end_date.blank? ? nil : end_date.to_date.strftime("%d%m%Y").to_i
      end
    end

    return start_date, end_date
  end
end