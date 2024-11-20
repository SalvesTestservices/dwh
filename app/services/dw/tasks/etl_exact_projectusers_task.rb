class Dw::Tasks::EtlExactProjectusersTask < Dw::Tasks::BaseExactTask
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
        account     = Account.find(run.account_id)
        dp_pipeline = run.dp_pipeline
        api_url, api_key, administration = get_api_keys("synergy")

        # Cancel the task if the API keys are not valid
        if api_url.blank? or api_key.blank? or administration.blank?
          Dw::DataPipelineLogger.new.create_log(run.id, "alert", "[#{account.name}] Invalid API keys")
          result.update(finished_at: DateTime.now, status: "error")
          return  
        end

        ### Extract projectusers

        # Scope user ids
        scoped_user_id = dp_pipeline.scoped_user_id.blank? ? "" : " and ResourceID eq #{dp_pipeline.scoped_user_id}"

        # Send the API GET request as long as the SkipToken is not empty (pagination)
        next_request = true
        skip_token = nil
        while next_request == true
          full_skip_token = skip_token.blank? ? nil : "&SkipToken=#{skip_token}"

          # Send the API GET request
          projectusers = send_get_request(api_url, api_key, administration, "/Synergy/ProjectMemberListFiltered?filter=FromDate ge DateTime'2020-01-01'#{scoped_user_id}#{full_skip_token}")

          # Set the next request
          if projectusers["SkipToken"] == "" or projectusers["SkipToken"].blank?
            next_request = false
            skip_token = nil
          else
            next_request = true
            skip_token = projectusers["SkipToken"] if skip_token.blank?
          end          

          ### Transform projectusers

          unless projectusers["Results"].blank?
            projectusers["Results"].each do |projectuser|
              dim_project = Dw::DimProject.find_by(original_id: projectuser["ProjectNumber"])
              dim_user    = Dw::DimUser.find_by(original_id: projectuser["ResourceID"])

              unless dim_project.blank? or dim_user.blank?
                start_date = projectuser["FromDate"].blank? ? nil : projectuser["FromDate"].to_date.strftime("%d%m%Y").to_i
                end_date = projectuser["UntilDate"].blank? ? nil : projectuser["UntilDate"].to_date.strftime("%d%m%Y").to_i

                projectuser_hash = Hash.new
                projectuser_hash[:original_id]        = projectuser["MemberID"]
                projectuser_hash[:project_id]         = dim_project.original_id
                projectuser_hash[:user_id]            = dim_user.original_id
                projectuser_hash[:start_date]         = start_date
                projectuser_hash[:end_date]           = end_date
                projectuser_hash[:expected_end_date]  = end_date
                projectuser_hash[:updated_at]         = DateTime.now.strftime("%d%m%Y").to_i

                Dw::EtlStorage.create!(account_id: account.id, identifier: "projectusers", etl: "transform", data: projectuser_hash)
              end
            end
          end
        end

        ### Load projectusers
        Dw::Loaders::ProjectusersLoader.new.load_data(account)
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
