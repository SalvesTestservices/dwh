class Dw::Tasks::EtlBbRatesTask < Dw::Tasks::BaseTask
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
      # Extract rates
      ActsAsTenant.without_tenant do
        account = Account.find(run.account_id)
        dp_pipeline = run.dp_pipeline
        year    = dp_pipeline.year.blank? ? Date.current.year : dp_pipeline.year.to_i
        month   = dp_pipeline.month.blank? ? Date.current.month : dp_pipeline.month.to_i

        companies = account.companies.where.not(id: get_excluded_company_ids)
        companies.each do |company|
          users = company.users.in_year(year)

          # Exclude roles
          users = users.where.not(role: get_excluded_roles)

          # Scope users 
          if dp_pipeline.scoped_user_id.present?
            users = users.where(id: dp_pipeline.scoped_user_id.to_i)
          end
          
          # Iterate users
          users.each do |user|
            user_hash = Hash.new
            calculator = DwCalculator.new
  
            if user.start_date <= Date.new(year, month, 1) and (user.leave_date.blank? or user.leave_date > Date.new(year, month, 1))
              contract_hours = calculator.contract_hours(user, month, year)
            else
              contract_hours = 0.0
            end

            user_hash[:user_id]         = user.id
            user_hash[:company_id]      = company.id
            user_hash[:rate_date]       = Date.new(year, month, 1).strftime("%d%m%Y").to_i
            user_hash[:avg_rate]        = calculator.avg_rate(user, month, year)
            user_hash[:hours]           = calculator.hours(user, month, year)
            user_hash[:bcr]             = calculator.bcr(user, month, year)
            user_hash[:ucr]             = calculator.ucr(user, month, year)
            user_hash[:company_bcr]     = calculator.company_bcr(company, year)
            user_hash[:company_ucr]     = calculator.company_ucr(company, year)
            user_hash[:contract]        = calculator.contract(user, month, year)
            user_hash[:contract_hours]  = contract_hours
            user_hash[:role]            = role_field(user, month, year)
            user_hash[:salary]          = calculator.user_salary(user, month, year)
            user_hash[:show_user]       = "Y"

            Dw::EtlStorage.create(account_id: account.id, identifier: "rates", etl: "transform", data: user_hash)
          end
        end

        # Load rates
        Dw::Loaders::RatesLoader.new.load_data(account)
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

  def role_field(user, month, year)
    calculator = DwCalculator.new
    
    if user.employee?
      user.trainee == true ? "Trainee" : I18n.t(".users.roles.#{calculator.role(user, month, year)}")
    else
      I18n.t(".users.roles.#{calculator.role(user, month, year)}")
    end
  end
end