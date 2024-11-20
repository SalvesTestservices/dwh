class Dw::Tasks::EtlBbProjectsTask < Dw::Tasks::BaseTask
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
      # Extract projects
      ActsAsTenant.without_tenant do
        account     = Account.find(run.account_id)
        dim_account = Dw::DimAccount.find_by(original_id: account.id)

        account_projects = account.projects.where.not(company_id: get_excluded_company_ids)  
        unless account_projects.blank?
          account_projects.each do |project|
            projectusers = project.projectusers
            unless projectusers.blank?
              first_projectuser = projectusers.order(:start_date).first
              start_date = first_projectuser.start_date.blank? ? nil : first_projectuser.start_date.strftime("%d%m%Y").to_i
  
              last_projectuser = projectusers.order(:end_date).last
              end_date = last_projectuser.end_date.blank? ? nil : last_projectuser.end_date.strftime("%d%m%Y").to_i
  
              if project.status.blank? or project.status == ""
                status = "not_started"
              else
                status = project.status
              end
  
              project_hash = Hash.new
              project_hash[:original_id]        = project.id
              project_hash[:name]               = project.name
              project_hash[:status]             = status
              project_hash[:company_id]         = project.company_id
              project_hash[:calculation_type]   = project.calculation_type
              project_hash[:start_date]         = start_date
              project_hash[:end_date]           = end_date
              project_hash[:expected_end_date]  = nil
              project_hash[:customer_id]        = project.customer_id
              project_hash[:updated_at]         = project.updated_at.strftime("%d%m%Y").to_i
  
              Dw::EtlStorage.create(account_id: account.id, identifier: "projects", etl: "transform", data: project_hash)
            end
          end
        end

        # Load projects
        Dw::Loaders::ProjectsLoader.new.load_data(account)

        # Update result
        result.update(finished_at: DateTime.now, status: "finished")
        Dw::DataPipelineLogger.new.create_log(run.id, "success", "[#{account.name}] Finished task [#{task.task_key}] successfully")
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
