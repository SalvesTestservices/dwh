class Dw::Tasks::EtlBbUsersTask < Dw::Tasks::BaseTask
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
      # Extract users
      ActsAsTenant.without_tenant do
        account     = Account.find(run.account_id)
        dp_pipeline = run.dp_pipeline
        companies   = account.companies.where.not(id: get_excluded_company_ids)
        companies.where(id:13).each do |company|
          users = company.users

          # Exclude roles
          users = users.where.not(role: get_excluded_roles)

          # Scope users 
          if dp_pipeline.scoped_user_id.present?
            users = users.where(id: dp_pipeline.scoped_user_id.to_i)
          end

          # Iterate users
          users.each do |user|
            leave_date = user.leave_date.blank? ? nil : user.leave_date.strftime("%d%m%Y").to_i
            salary = user.salary.blank? ? 0 : user.salary
  
            users_hash = Hash.new
            users_hash[:original_id]    = user.id
            users_hash[:full_name]      = user.full_name
            users_hash[:company_id]     = company.id
            users_hash[:start_date]     = user.start_date.strftime("%d%m%Y").to_i
            users_hash[:leave_date]     = leave_date
            users_hash[:role]           = role_field(user)
            users_hash[:email]          = user.email
            users_hash[:employee_type]  = employee_type_field(user)
            users_hash[:contract]       = contract_field(user.contract)
            users_hash[:contract_hours] = user.contract_hours
            users_hash[:salary]         = salary
            users_hash[:address]        = user.address
            users_hash[:zipcode]        = user.zipcode
            users_hash[:city]           = user.city
            users_hash[:country]        = user.country
            users_hash[:updated_at]     = user.updated_at.strftime("%d%m%Y").to_i
  
            Dw::EtlStorage.create(account_id: account.id, identifier: "users", etl: "transform", data: users_hash)
          end

          # Load users
          Dw::Loaders::UsersLoader.new.load_data(account)

          # Data qualtiy check: general
          dim_account = Dw::DimAccount.find_by(original_id: account.id)
          dim_company = Dw::DimCompany.find_by(original_id: company.id)
          expected    = company.users.where.not(role: get_excluded_roles)          

          # Data quality check: row count
          actual = Dw::DimUser.where(account_id: dim_account.id, company_id: dim_company.id).count
          perform_quality_check("row_count", run, task, actual, expected.count, "[#{company.name_short}] aantal users")

          # Data quality check: row_count for contract hours
          #actual = Dw::DimUser.where(account_id: dim_account.id, company_id: dim_company.id).where("role != 'Subco' AND contract_hours IS NOT NULL AND contract_hours > 0").count
          #perform_quality_check("row_count", run, task, actual, expected.count, "[#{company.name_short}] contract uren gevuld")
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

  private def role_group(user)
    if user.trainee == true
      role_group = "Trainee"
    elsif user.external?
      role_group = "Subco"
    else
      role_group = "Medewerker"
    end
  end
end
