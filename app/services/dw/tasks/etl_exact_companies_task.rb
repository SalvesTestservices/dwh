class Dw::Tasks::EtlExactCompaniesTask < Dw::Tasks::BaseExactTask
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

        api_url, api_key, administration = get_api_keys("synergy")

        # Cancel the task if the API keys are not valid
        if api_url.blank? or api_key.blank? or administration.blank?
          Dw::DataPipelineLogger.new.create_log(run.id, "alert", "[#{account.name}] Invalid API keys")
          result.update(finished_at: DateTime.now, status: "error")
          return  
        end

        ### Extract companies

        # Send the API GET request
        companies = send_get_request(api_url, api_key, administration, "/Synergy/CostCenter/Active/eq/true")

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
              companies_hash[:name_short]   = company["Code"].gsub(company["CompanyCode"], "")
              companies_hash[:updated_at]   = company["ModifiedDate"].to_date.strftime("%d%m%Y").to_i

              Dw::EtlStorage.create(account_id: account.id, identifier: "companies", etl: "transform", data: companies_hash)
            end
          end
        end

        ### Load companies
        Dw::Loaders::CompaniesLoader.new.load_data(account)
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
