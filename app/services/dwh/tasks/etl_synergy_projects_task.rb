class Dwh::Tasks::EtlSynergyProjectsTask < Dwh::Tasks::BaseSynergyTask
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
      account     = Account.find(task_account_id)
      dim_account = Dwh::DimAccount.find_by(original_id: account.id)

      api_url, api_key, administration = get_api_keys("synergy", account.id)

      # Cancel the task if the API keys are not valid
      if api_url.blank? or api_key.blank? or administration.blank?
        Dwh::DataPipelineLogger.new.create_log(run.id, "alert", "[#{task_account_name}] Invalid API keys")
        result.update(finished_at: DateTime.now, status: "error")
        return  
      end

      ### Extract projects

      # Send the API GET request as long as the SkipToken is not empty (pagination)
      next_request = true
      skip_token = nil
      while next_request == true
        full_skip_token = skip_token.blank? ? nil : "&SkipToken=#{skip_token}"

        # Send the API GET request
        projects = send_get_request(api_url, api_key, administration, "/Synergy/ProjectListFiltered?filter=ModifiedDate ge DateTime'#{get_history_date(run.dp_pipeline.get_history)}'#{full_skip_token}")

        # Set the next request
        if projects["Message"].present? and projects["Message"] == "An error has occurred."
          next_request = true
        elsif projects["SkipToken"] == "" or projects["SkipToken"].blank?
          next_request = false
          skip_token = nil
        else
          next_request = true
          skip_token = projects["SkipToken"] if skip_token.blank?
        end

        ### Transform projects
        
        unless projects["Results"].blank?              
          projects["Results"].each do |project|
            unless unbillable_work_project_numbers.map(&:strip).include?(project["ProjectNumber"])
              dim_customer = Dwh::DimCustomer.find_by(original_id: project["CustomerID"])
              dim_customer = Dwh::DimCustomer.find_by(original_id: project["CustomerID"])
              dim_customer_id = dim_customer.blank? ? nil : dim_customer.original_id

              status = project["Status"] == "G" ? "inactive" : "active"
              calculation_type = project["Type"] == "F" ? "fixed_price" : "hour_based"
              calculation_type = "service" if project["Description"].downcase.include?("josf")

              start_date = project["StartDate"].blank? ? nil : project["StartDate"].to_date.strftime("%d%m%Y").to_i
              end_date = project["EndDate"].blank? ? nil : project["EndDate"].to_date.strftime("%d%m%Y").to_i
              expected_end_date = project["ExpectedEndDate"].blank? ? nil : project["ExpectedEndDate"].to_date.strftime("%d%m%Y").to_i
              expected_end_date = end_date if expected_end_date.blank?
              company_id = project["ProjectCostCenter"].blank? ? nil : project["ProjectCostCenter"].gsub(project["CompanyCode"].gsub("CC", ""), "")

              project_hash = Hash.new
              project_hash[:original_id]        = project["ProjectNumber"].strip
              project_hash[:name]               = project["Description"]
              project_hash[:status]             = status
              project_hash[:company_id]         = company_id
              project_hash[:calculation_type]   = calculation_type
              project_hash[:start_date]         = start_date
              project_hash[:end_date]           = end_date
              project_hash[:expected_end_date]  = expected_end_date
              project_hash[:broker_id]          = set_broker(project["ProjectNumber"].strip)
              project_hash[:customer_id]        = dim_customer_id
              project_hash[:updated_at]         = project["ModifiedDate"].to_date.strftime("%d%m%Y").to_i

              Dwh::EtlStorage.create(account_id: account.id, identifier: "projects", etl: "transform", data: project_hash)
            end
          end
        end
      end

      ### Load projects
      Dwh::Loaders::ProjectsLoader.new.load_data(account)

      # Update result
      result.update(finished_at: DateTime.now, status: "finished")
      Dwh::DataPipelineLogger.new.create_log(run.id, "success", "[#{task_account_name}] Finished task [#{task.task_key}] successfully")      
    rescue => e
      # Update result to failed if an error occurs
      result.update(finished_at: DateTime.now, status: "failed", error: e.message)
      Dwh::DataPipelineLogger.new.create_log(run.id, "alert", "[#{task_account_name}] Finished task [#{task.task_key}] with error: #{e.message}")
    end
  end

  private def set_broker(project_number)
    broker = nil

    unless project_number.blank?
      broker = create_or_find_broker(project_number)
    end

    broker
  end

  private def create_or_find_broker(project_number)
    broker_id = nil
    # Get globe keys
    api_url, api_key, administration = get_api_keys("globe")

    # First get a verification code
    query = "SELECT * FROM frhkrg (NOLOCK) WHERE ProjectNr = '#{project_number}'"    
    body = send_custom_query(api_url, api_key, administration, "", query)

    # When there are no errors, then the verification code can be used to get the data
    if body["Errors"].blank?
      body = send_custom_query(api_url, api_key, administration, "#{body["VerificationCode"]}", query)

      # Iterate over the results and get the sales price of the valid item
      if body["Errors"].blank?
        broker_data = body["Results"].first
        unless broker_data.blank?
          broker_name = broker_data["inv_debtor_name"]
          unless broker_name.blank? or broker_name == ""
            broker_email = broker_data["inv_contactemail"]

            # First match on email
            broker = Dw::DimBroker.find_by(email: broker_email)
            if broker.blank?
              # Match on normalized name
              normalized_name = normalize_broker_name(broker_name)
              broker = Dw::DimBroker.find_by(name: normalized_name)
              if broker.blank?
                # Create new broker
                broker = Dw::DimBroker.create(name: normalized_name, email: broker_email)
              else
                # Update email if it exists
                broker.update(email: broker_email) unless broker_email.blank? or broker_email == broker.email
              end
            end
            broker_id = broker.blank? ? nil : broker.id
          end
        end
      end
    end
    broker_id
  end

  private def normalize_broker_name(name)
    name
      .gsub(/\s*[bB]\.?[vV]\.?\s*$/, '')  # Remove B.V. or BV at the end
      .gsub(/\s*nederland\s*$/i, '')       # Remove Nederland at the end (case insensitive)
      .gsub(/\s+/, '')                     # Remove ALL spaces
      .downcase                            # Convert to lowercase
      .capitalize                          # Capitalize the first letter of each word
      .strip
  end
end
