class Dwh::Tasks::EtlSynergyCustomersTask < Dwh::Tasks::BaseSynergyTask
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

      ### Extract customers

      # Send the API GET request as long as the SkipToken is not empty (pagination)
      next_request = true
      skip_token = nil
      while next_request == true
        full_skip_token = skip_token.blank? ? nil : "&SkipToken=#{skip_token}"

        # Send the API GET request
        customers = send_get_request(api_url, api_key, administration, "/Synergy/AccountListFiltered?filter=ModifiedDate ge DateTime'2020-01-01'#{full_skip_token}")

        # Set the next request
        if customers["SkipToken"] == "" or customers["SkipToken"].blank?
          next_request = false
          skip_token = nil
        else
          next_request = true
          skip_token = customers["SkipToken"] if skip_token.blank?
        end

        ### Transform customers
        unless customers["Results"].blank?
          customers["Results"].each do |customer|
            if customer["CustomerType"] == "C"
              status = customer["CustomerType"] == "C" ? "active" : "inactive"
        
              customers_hash = Hash.new
              customers_hash[:original_id]  = customer["ID"].strip
              customers_hash[:name]         = customer["AccountName"]
              customers_hash[:status]       = status
              customers_hash[:updated_at]   = customer["ModifiedDate"].to_date.strftime("%d%m%Y").to_i
        
              Dwh::EtlStorage.create(account_id: account.id, identifier: "customers", etl: "transform", data: customers_hash)
            end
          end
        end

        ### Load customers
        Dwh::Loaders::CustomersLoader.new.load_data(account)
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
