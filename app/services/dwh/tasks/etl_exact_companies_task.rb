class Dwh::Tasks::EtlExactCompaniesTask < Dwh::Tasks::BaseExactTask
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
      # Extract companies
      account = Account.find(task_account_id)

      api_url, api_key, administration = get_api_keys("synergy")

      # Cancel the task if the API keys are not valid
      if api_url.blank? or api_key.blank? or administration.blank?
        Dwh::DataPipelineLogger.new.create_log(run.id, "alert", "[#{task_account_name}] Invalid API keys")
        result.update(finished_at: DateTime.now, status: "error")
        return  
      end

      ### Extract companies

      # Send the API GET request
      companies = send_get_request(api_url, api_key, administration, "/Synergy/CostCenter/Active/eq/true")

      # Cancel the task if the response is not valid
      if companies.blank? or companies.include?("CONNECTION ERROR")
        Dwh::DataPipelineLogger.new.create_log(run.id, "alert", "[#{task_account_name}] Connection error")
        result.update(finished_at: DateTime.now, status: "error")
        return  
      end

      ### Transform companies

      # Set a list of desired companies
      desired_companies = Array.new
      desired_companies << "Unit Business IT Improvement"
      desired_companies << "Unit Testautomation Engineering (TAE)"
      desired_companies << "Unit Testautomation Specialists (TAS)"
      desired_companies << "Unit Low Code Testing"
      desired_companies << "Unit Agile Testing 1"
      desired_companies << "Unit Agile Testing 2"
      desired_companies << "Unit Testautomation Architects (TAA)"
      desired_companies << "Unit QA& Test Advisory"
      desired_companies << "Unit Valori"

      unless companies.blank?
        companies.each do |company|
          if desired_companies.include?(company["Description"]) and company["CompanyCode"] == "001"
            companies_hash = Hash.new
            companies_hash[:account_id]   = account.id
            companies_hash[:original_id]  = company["Code"].gsub(company["CompanyCode"], "")
            companies_hash[:name]         = company["Description"]
            companies_hash[:name_short]   = company["Code"].gsub(company["CompanyCode"], "").gsub("CC", "")
            companies_hash[:updated_at]   = company["ModifiedDate"].to_date.strftime("%d%m%Y").to_i

            Dwh::EtlStorage.create(account_id: account.id, identifier: "companies", etl: "transform", data: companies_hash)
          end
        end
      end

      ### Load companies
      Dwh::Loaders::CompaniesLoader.new.load_data(account)

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
