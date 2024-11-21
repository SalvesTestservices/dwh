class Dwh::Tasks::EtlBbProjectusersTask < Dwh::Tasks::BaseTask
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
      # Extract projectusers
      ActsAsTenant.without_tenant do
        account     = Account.find(run.account_id)
        dp_pipeline = run.dp_pipeline

        # Skip old companies
        users = account.users.where.not(company_id: get_excluded_company_ids)

        # Exclude roles
        users = users.where.not(role: get_excluded_roles)

        # Scope users 
        if dp_pipeline.scoped_user_id.present?
          users = users.where(id: dp_pipeline.scoped_user_id.to_i)
        end
        
        projectuser_ids = account.projectusers.where(user_id: users.pluck(:id)).pluck(:id)        
        projectusers = account.projectusers.where(id: projectuser_ids)
  
        unless projectusers.blank?
          projectusers.each do |projectuser|
            start_date        = projectuser.start_date.blank? ? nil : projectuser.start_date.strftime("%d%m%Y").to_i
            end_date          = projectuser.end_date.blank? ? nil : projectuser.end_date.strftime("%d%m%Y").to_i
            expected_end_date = projectuser.expected_end_date.blank? ? end_date : projectuser.expected_end_date.strftime("%d%m%Y").to_i
  
            projectuser_hash = Hash.new
            projectuser_hash[:original_id]        = projectuser.id
            projectuser_hash[:project_id]         = projectuser.project_id
            projectuser_hash[:user_id]            = projectuser.user_id
            projectuser_hash[:start_date]         = start_date
            projectuser_hash[:end_date]           = end_date
            projectuser_hash[:expected_end_date]  = expected_end_date
            projectuser_hash[:updated_at]         = projectuser.updated_at.strftime("%d%m%Y").to_i
  
            Dwh::EtlStorage.create(account_id: account.id, identifier: "projectusers", etl: "transform", data: projectuser_hash)
          end
        end

        # Load projectusers
        Dwh::Loaders::ProjectusersLoader.new.load_data(account)
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
