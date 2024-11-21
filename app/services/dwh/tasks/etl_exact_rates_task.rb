class Dwh::Tasks::EtlExactRatesTask < Dwh::Tasks::BaseExactTask
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
      # Extract rates
      ActsAsTenant.without_tenant do
        account = Account.find(run.account_id)
        dim_account = Dwh::DimAccount.find_by(original_id: account.id)
        dp_pipeline = run.dp_pipeline
        year    = dp_pipeline.year.blank? ? Date.current.year : dp_pipeline.year.to_i
        month   = dp_pipeline.month.blank? ? Date.current.month : dp_pipeline.month.to_i

        api_url, api_key, administration = get_api_keys("synergy")

        # Cancel the task if the API keys are not valid
        if api_url.blank? or api_key.blank? or administration.blank?
          Dwh::DataPipelineLogger.new.create_log(run.id, "alert", "[#{account.name}] Invalid API keys")
          result.update(finished_at: DateTime.now, status: "error")
          return  
        end

        # Scope users 
        if dp_pipeline.scoped_user_id.blank?
          dim_users = Dwh::DimUser.where(account_id: dim_account.id)
        else
          dim_users = Dwh::DimUser.where(account_id: dim_account.id, original_id: dp_pipeline.scoped_user_id.to_i)
        end

        # Iterate the users
        unless dim_users.blank?
          dim_users.each do |dim_user|
            # Check if the user is employed in the given month
            employed = true

            if dim_user.leave_date.present?
              leave_date = dim_user.leave_date.to_s.length == 7 ? "0#{dim_user.leave_date}" : dim_user.leave_date.to_s
              leave_date_as_date = Date.strptime(leave_date, '%d%m%Y')
              check_date = Date.new(year, month, 1)
              employed = leave_date_as_date >= check_date ? true : false
            end
    
            if employed == true
              start_date = dim_user.start_date.to_s.rjust(8, '0')
              unless start_date.blank? or start_date == "00000000"
                start_date_as_date = Date.strptime(start_date, '%d%m%Y')

                valid_hr_data = get_valid_hr_data(api_url, api_key, administration, dim_user.original_id, month, year)
                if valid_hr_data.blank? || start_date_as_date > Date.current
                  # Send email to notify of missing hr data
                  UserMailer.dwh_email("Geen HR data aanwezig voor: #{dim_user.full_name} (ID: #{dim_user.original_id})").deliver_later
                else
                  # Get company
                  dim_company = Dwh::DimCompany.find_by(id: dim_user.company_id)
                  unless dim_company.blank?
                    # Get all hours and average rate for the user for the month
                    avg_rate, hours = calculate_avg_rate_and_hours(api_url, api_key, administration, dim_user.original_id, month, year)

                    # Set BCR
                    bcr = calculate_bcr(api_url, api_key, administration, dim_user.original_id, valid_hr_data["TextFreeField3"],valid_hr_data["TextFreeField8"], month, year)

                    # Set contract and contract hours
                    contract = valid_hr_data["TextFreeField2"] == "Onbepaalde tijd" ? "fixed" : "temporary"

                    if user_employed_in_month(dim_user, month, year)
                      contract_hours = valid_hr_data["TextFreeField4"].blank? ? 40 : ((valid_hr_data["TextFreeField4"].to_f / 100.0 ) * 40).round(1)
                    else
                      contract_hours = 0
                    end

                    unless bcr == "n/a"
                      user_hash = Hash.new
                      user_hash[:user_id]         = dim_user.original_id
                      user_hash[:company_id]      = dim_company.original_id
                      user_hash[:rate_date]       = Date.new(year, month, 1).strftime("%d%m%Y").to_i
                      user_hash[:avg_rate]        = avg_rate
                      user_hash[:hours]           = hours
                      user_hash[:bcr]             = bcr
                      user_hash[:ucr]             = nil
                      user_hash[:company_bcr]     = nil
                      user_hash[:company_ucr]     = nil
                      user_hash[:contract]        = contract
                      user_hash[:contract_hours]  = contract_hours
                      user_hash[:role]            = dim_user.role
                      user_hash[:salary]          = valid_hr_data["Amount"]
                      user_hash[:show_user]       = "Y"

                      Dwh::EtlStorage.create(account_id: account.id, identifier: "rates", etl: "transform", data: user_hash)
                    end
                  end
                end
              end
            end
          end
        end

        # Load rates
        Dwh::Loaders::RatesLoader.new.load_data(account)
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

  private def calculate_bcr(api_url, api_key, administration, user_id, c_level, profile, month, year)
    bcr = 0.0

    fixed_bcr_values = {
      "195" => 73.20,
      "100" => 81.00,
      "114" => 87.08,
      "159" => 80.63,
      "164" => 79.39,
      "253" => 71.06,
      "442" => 92.50,
      "448" => 115.0,
      "469" => 90.0,
      "481" => 103.8,
      "484" => 110.0,
      "486" => 85.0,
      "502" => 82.8,
      "509" => 85.0,
      "518" => 100.5
    }

    if fixed_bcr_values.key?(user_id)
      bcr = fixed_bcr_values[user_id]
    else
      # First get a verification code
      query = "SELECT r.ID, r.Res_id as EmployeeID, r.ItemCode,i.Description,r.StartDate, r.EndDate, r.SalesPrice, r.Rate, r.CurrencyCost, r.CurrencySalesPrice, r.IntercompanyRate, r.UseSalesRate, r.UseCostRate, i.Type, r.CurrencyIntercompany FROM TimeSheetInternalRates r WITH (nolock) LEFT OUTER JOIN items i WITH (NOLOCK) ON i.Itemcode = r.Itemcode left outer join humres with (nolock) on r.Res_id = humres.res_id WHERE r.Res_id = #{user_id} ORDER BY r.Res_id,r.Ratetype,r.Itemcode, r.StartDate"    
      body = send_custom_query(api_url, api_key, administration, "", query)

      # When there are no errors, then the verification code can be used to get the data
      if body["Errors"].blank?
        body = send_custom_query(api_url, api_key, administration, "#{body["VerificationCode"]}", query)

        # Iterate over the results and get the sales price of the valid item
        if body["Errors"].blank?
          hr_data = body["Results"]
          valid_hr_data = hr_data
            .select do |item|
              start_date = Date.parse(item["StartDate"])
              (start_date.year < year) || (start_date.year == year && start_date.month <= month)
            end
            .sort_by { |item| Date.parse(item["StartDate"]) }
            .last

          unless valid_hr_data.blank?
            # Get sales price
            sales_price = valid_hr_data["SalesPrice"].to_f

            # Set c_level and profile table
            table = [
              { "c_level" => "Consultant 1", "Basis" => 22.5, "Basis plus" => nil, "Ondernemend" => nil, "Ondernemend plus" => nil },
              { "c_level" => "Consultant 2", "Basis" => 42.5, "Basis plus" => 41, "Ondernemend" => nil, "Ondernemend plus" => nil },
              { "c_level" => "Consultant 3", "Basis" => 42.5, "Basis plus" => 41.5, "Ondernemend" => 40, "Ondernemend plus" => 36.5 },
              { "c_level" => "Consultant 4", "Basis" => 42.5, "Basis plus" => 41, "Ondernemend" => 40, "Ondernemend plus" => 35.5 },
              { "c_level" => "Consultant 5", "Basis" => nil, "Basis plus" => 41, "Ondernemend" => 39.5, "Ondernemend plus" => 35.5 },
              { "c_level" => "Consultant 6", "Basis" => nil, "Basis plus" => nil, "Ondernemend" => 39, "Ondernemend plus" => 35.5 },
            ]

            # Translate or skip different c_level or profile
            c_level_exists = table.any? { |item| item["c_level"] == c_level }
            if c_level_exists
              unless profile.downcase == "neutraal"
                # Translate profile
                profile = "Basis" if profile == "Geen" or profile == "Masterclass"

                # Get correct item
                correct_item = table.find { |item| item["c_level"] == c_level }

                # Calculate BCR
                if correct_item.blank? or correct_item[profile].blank? or sales_price.blank? or profile.blank?
                  bcr = "n/a"
                else
                  perc = correct_item[profile]
                  bcr = (((100 - perc) * sales_price)/100.0).round(2)
                end
              end
            end
          end
        end
      end
    end
    bcr
  end

  private def calculate_avg_rate_and_hours(api_url, api_key, administration, user_id, month, year)
    # Set default values
    avg_rate = 0.0
    total_hours = 0.0
    weighted_rate = 0.0

    # First and last day of the month
    first_day = Date.new(year, month, 1).strftime("%Y-%m-%d")
    last_day = Date.civil(year, month, -1).strftime("%Y-%m-%d")

    # Get all activities for the user for the month
    activities = send_get_request(api_url, api_key, administration, "/Synergy/RequestListFiltered?filter=RequestType eq 9050 and ResourceID eq #{user_id} and StartDate ge DateTime'#{first_day}' and StartDate le DateTime'#{last_day}'")    
    unless activities["Results"].blank?
      activities["Results"].each do |activity|
        unless activity["AccountCode"].blank?
          hours = activity["DurationInHourRealized"].to_f
          amount = activity["AmountRealized"].to_f
          rate = hours > 0 ? amount / hours : 0
          weighted_rate += rate * hours
          total_hours += hours
        end
      end
    end

    # Calculate average weighted rate
    avg_rate = total_hours > 0 ? weighted_rate / total_hours : 0

    return avg_rate, total_hours
  end

  private def user_employed_in_month(dim_user, month, year)
    # Convert start_date and end_date to Date objects
    start_date = dim_user.start_date.blank? ? Date::Infinity.new : Date.strptime(dim_user.start_date.to_s.rjust(8, '0'), '%d%m%Y')
    leave_date = dim_user.leave_date.blank? ? Date::Infinity.new : Date.strptime(dim_user.leave_date.to_s.rjust(8, '0'), '%d%m%Y')
  
    # Create a Date object for the first day of the given month and year
    given_date = Date.new(year, month)
  
    # Check if the given date is within the range of the start and end dates
    (start_date..leave_date).cover?(given_date)
  end
end