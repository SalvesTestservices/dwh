class Dw::Tasks::EtlBbCompaniesTask < Dw::Tasks::BaseTask
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
      # Extract companies
      ActsAsTenant.without_tenant do
        account     = Account.find(run.account_id)
        dim_account = Dw::DimAccount.find_by(original_id: account.id)
        companies   = account.companies

        # Skip old companies
        companies = companies.where.not(id: get_excluded_company_ids)

        unless companies.blank?
          companies.each do |company|
            companies_hash = Hash.new
            companies_hash[:original_id]  = company.id
            companies_hash[:name]         = company.name
            companies_hash[:name_short]   = company.name_short
            companies_hash[:updated_at]   = company.updated_at.strftime("%d%m%Y").to_i

            Dw::EtlStorage.create(account_id: account.id, identifier: "companies", etl: "transform", data: companies_hash)
          end
        end

        # Load companies
        Dw::Loaders::CompaniesLoader.new.load_data(account)
        
        # Data quality check: row count
        expected    = account.companies.where.not(id: get_excluded_company_ids).count
        actual      = Dw::DimCompany.where(account_id: dim_account.id).count + 1
        perform_quality_check("row_count", run, task, actual, expected)
        
        # Update result
        result.update(finished_at: DateTime.now, status: "finished")
        Dw::DataPipelineLogger.new.create_log(run.id, "success", "[#{account.name}] Finished task [#{task.task_key}] successfully")
      end
    rescue => e
      # Update result to failed if an error occurs
      result.update(finished_at: DateTime.now, status: "failed", error: e.message)
      Dw::DataPipelineLogger.new.create_log(run.id, "alert", "[#{account.name}] Finished task [#{task.task_key}] with error: #{e.message}")
    end
  end
end
