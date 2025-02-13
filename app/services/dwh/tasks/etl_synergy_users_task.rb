class Dwh::Tasks::EtlSynergyUsersTask < Dwh::Tasks::BaseSynergyTask
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
      # Extract users
      account     = Account.find(task_account_id)
      dp_pipeline = run.dp_pipeline
      api_url, api_key, administration = get_api_keys("synergy", account.id)

      # Cancel the task if the API keys are not valid
      if api_url.blank? or api_key.blank? or administration.blank?
        Dwh::DataPipelineLogger.new.create_log(run.id, "alert", "[#{task_account_name}] Invalid API keys")
        result.update(finished_at: DateTime.now, status: "error")
        return  
      end

      ### Extract users

      # Set excluded user ids
      excluded_user_ids = [48, 50, 167, 516, 439, 503, 494, 493, 470, 440, 437, 434, 429, 424, 425, 415, 403, 398, 396, 377, 374, 372, 370, 360, 352, 346, 344, 334, 331, 323, 319, 318, 305, 304, 276, 263, 262, 259, 246, 245, 244, 227, 205, 197, 191, 141, 186, 180, 162, 160, 158, 153, 152, 149, 145, 139, 137, 136, 128, 123, 112, 109, 107, 105, 102, 23, 22, 21, 20, 19, 18, 17, 16, 15, 13, 12, 11, 10, 527]

      # 397 MArcel de Keizer has been removed from the list of excluded users
      
      # Scope user ids
      scoped_user_id = dp_pipeline.scoped_user_id.blank? ? "" : " and ID eq #{dp_pipeline.scoped_user_id}"

      # Send the API GET request as long as the SkipToken is not empty (pagination)
      next_request = true
      skip_token = nil
      while next_request == true
        full_skip_token = skip_token.blank? ? nil : "&SkipToken=#{skip_token}"

        # Send the API GET request
        users = send_get_request(api_url, api_key, administration, "/Synergy/ResourceListFiltered?filter=ModifiedDate ge DateTime'2020-01-01'#{scoped_user_id}#{full_skip_token}")

        # Set the next request
        if users["SkipToken"] == "" or users["SkipToken"].blank?
          next_request = false
          skip_token = nil
        else
          next_request = true
          skip_token = users["SkipToken"] if skip_token.blank?
        end          
        
        ### Transform users
        unless users["Results"].blank?
          users["Results"].each do |user|
            unless excluded_user_ids.include?(user["ID"])
              dim_company = Dwh::DimCompany.find_by(name_short: user["CostCenter"].gsub(user["CompanyCode"], ""))
              unless dim_company.blank?
                contract = get_contract(user["ID"])
                contract_hours = (user["FTE"].to_f * 40).round(1)
                start_date, end_date = get_employment_dates(api_url, api_key, administration, user["ID"])

                # Exception for soecific user
                end_date = 30042024 if user["ID"].to_i == 167

                # Get salary
                request_list = send_get_request(api_url, api_key, administration, "Synergy/RequestListFiltered?filter=RequestType eq 1060015 and ResourceID eq #{user["ID"]}")
                if request_list["Results"].blank?
                  salary = 0
                else
                  salary = request_list["Results"].last["Amount"].to_f
                end

                # Set country
                case user["CountryCode"]
                when "NL"
                  country = "Nederland"
                when "BE"
                  country = "Belgie"
                when "ES"
                  country = "Spanje"
                end

                # Set role by first checking if user is a trainee and otherwise get the role from the job title
                valid_hr_data = get_valid_hr_data(api_url, api_key, administration, user["ID"], Date.current.month, Date.current.year)

                if dim_company.name_short == "CCVAL"
                  role = "Subco"
                else
                  role = "Medewerker"
                end

                users_hash = Hash.new
                users_hash[:original_id]    = user["ID"]
                users_hash[:full_name]      = user["FullName"]
                users_hash[:company_id]     = dim_company.original_id
                users_hash[:start_date]     = start_date
                users_hash[:leave_date]     = end_date
                users_hash[:role]           = role
                users_hash[:email]          = user["EmailWork"]
                users_hash[:employee_type]  = "Consultant"
                users_hash[:contract]       = contract
                users_hash[:contract_hours] = contract_hours
                users_hash[:salary]         = salary
                users_hash[:address]        = "#{user["AddressLine1"]} #{user["AddressHouseNumber"]}"
                users_hash[:zipcode]        = user["Postcode"]
                users_hash[:city]           = user["City"]
                users_hash[:country]        = country
                users_hash[:updated_at]     = user["ModifiedDate"].to_date.strftime("%d%m%Y").to_i


                Dwh::EtlStorage.create(account_id: account.id, identifier: "users", etl: "transform", data: users_hash)
              end
            end
          end
        end

        ### Load users
        Dwh::Loaders::UsersLoader.new.load_data(account)
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

  private def get_employment_dates(api_url, api_key, administration, user_id)
    start_date = nil
    end_date = nil

    # First get a verification code
    query = "SELECT absences.ID AS ID, absences.HID AS HID, absences.EmpID as EmployeeID, absences.FreeTextField_01 AS Type, absences.FreeTextField_15 AS TypeDesc, absences.startdate AS StartDate, absences.enddate AS EndDate, absences.Description AS Description FROM absences WHERE absences.Type=11001 AND absences.EmpID=#{user_id} ORDER BY Absences.EmpID, absences.FreeTextField_15,absences.startdate,absences.HID"    
    body = send_custom_query(api_url, api_key, administration, "", query)

    # When there are no errors, then the verification code can be used to get the data
    if body["Errors"].blank?
      body = send_custom_query(api_url, api_key, administration, "#{body["VerificationCode"]}", query)

      # Iterate over the results and get the sales price of the valid item
      if body["Errors"].blank? and body["Results"].any?
        # Sort the results by StartDate
        sorted_results = body["Results"].sort_by { |result| result["StartDate"] }

        # Get the StartDate of the first result and the EndDate of the last result
        start_date = sorted_results.first["StartDate"]
        end_date = sorted_results.last["EndDate"]

        # Convert the dates to the correct format
        start_date = start_date.blank? ? nil : start_date.to_date.strftime("%d%m%Y").to_i
        end_date = end_date.blank? ? nil : end_date.to_date.strftime("%d%m%Y").to_i
      end
    end

    return start_date, end_date
  end
end