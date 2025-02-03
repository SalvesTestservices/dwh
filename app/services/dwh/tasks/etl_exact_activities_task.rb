class Dwh::Tasks::EtlExactActivitiesTask < Dwh::Tasks::BaseExactTask
  queue_as :default

  def perform(task_account_id, task_account_name, run, result, task)
    # Wait for alle dependencies to finish
    all_dependencies_finished = wait_on_dependencies(task_account_name, run, task)
    if all_dependencies_finished == false
      Dwh::DataPipelineLogger.new.create_log(run.id, "alert", "[#{task_account_name}] taak [#{task.task_key}] geannuleerd")
      result.update(finished_at: DateTime.now, status: "cancelled")
      return
    end

    begin
      account              = Account.find(task_account_id)
      dim_account          = Dwh::DimAccount.find_by(original_id: account.id)
      dp_pipeline          = run.dp_pipeline
      year                 = run.dp_pipeline.year.blank? ? Date.current.year : run.dp_pipeline.year.to_i
      month                = run.dp_pipeline.month.blank? ? Date.current.month : run.dp_pipeline.month.to_i
      previous_month_start = Date.new(year, month, 1).prev_month.strftime("%Y-%m-%d")
      previous_month_end   = (Date.new(year, month, 1) - 1).strftime("%Y-%m-%d")

      # Cancel the task if the API keys are not valid
      api_url, api_key, administration = get_api_keys("synergy")
      if api_url.blank? or api_key.blank? or administration.blank?
        Dwh::DataPipelineLogger.new.create_log(run.id, "alert", "[#{task_account_name}] Invalid API keys")
        result.update(finished_at: DateTime.now, status: "error")
        return  
      end

      # Scope users 
      if dp_pipeline.scoped_user_id.blank?
        dim_users = Dwh::DimUser.where(account_id: dim_account.id)
      else
        dim_users = Dwh::DimUser.where(account_id: dim_account.id, original_id: dp_pipeline.scoped_user_id.to_i)
      end

      # Get activities for user(s)
      unless dim_users.blank?
        dim_users.each do |dim_user|
          ### Extract billable activities

          # Send the API GET request as long as the SkipToken is not empty (pagination)
          next_request = true
          skip_token = nil
          while next_request == true
            skip_token = skip_token.blank? ? nil : "&SkipToken=#{skip_token}"

            # Get all activities for month
            activities = send_get_request(api_url, api_key, administration, "Synergy/RequestListFiltered?filter=RequestType eq 9050 and StatusDescription ne 'Open' and StatusDescription ne 'Concept' and StatusDescription ne 'Rejected' and ResourceID eq #{dim_user.original_id} and StartDate ge DateTime'#{previous_month_start}' and StartDate le DateTime'#{previous_month_end}'#{skip_token}")

            ### Transform activities
            
            # Set the next request
            if activities == "CONNECTION ERROR"
              next_request = true
            elsif activities["SkipToken"] == "" or activities["SkipToken"].blank?
              next_request = false
              skip_token = nil
            else
              next_request = true
              skip_token = activities["SkipToken"]
            end

            # Iterate activities
            unless activities["Results"].blank?
              activities["Results"].each do |activity|
                if unbillable_activity?(activity)
                  create_unbillable_activity("billable", account, activity)
                else
                  # Set customer
                  if activity["AccountID"].blank?
                    customer_id = nil
                  else
                    dim_customer = Dwh::DimCustomer.find_by(account_id: dim_account.id, original_id: activity["AccountID"].to_s.strip)
                    customer_id = dim_customer.blank? ? nil : dim_customer.original_id
                  end

                  # Set project
                  if activity["ProjectNumber"].blank?
                    project_id = nil
                  else
                    dim_project = Dwh::DimProject.find_by(account_id: dim_account.id, original_id: activity["ProjectNumber"].to_s.strip)
                    project_id = dim_project.blank? ? nil : dim_project.original_id
                  end

                  # Set user
                  if activity["ResourceID"].blank?
                    user_id = nil
                    company_id = nil
                  else
                    dim_user = Dwh::DimUser.find_by(account_id: dim_account.id, original_id: activity["ResourceID"].to_s.strip)
                    user_id = dim_user.blank? ? nil : dim_user.original_id

                    if user_id.blank?
                      company_id = nil
                    else
                      dim_company = Dwh::DimCompany.find_by(account_id: dim_account.id, id: dim_user.company_id)
                      company_id = dim_company.blank? ? nil : dim_company.original_id
                    end
                  end

                  # Set projectuser
                  if dim_user.blank? or dim_project.blank?
                    projectuser_id = nil
                  else
                    fact_projectuser = Dwh::FactProjectuser.find_by(account_id: dim_account.id, user_id:dim_user.id, project_id: dim_project.id)
                    projectuser_id = fact_projectuser.blank? ? nil : fact_projectuser.original_id
                  end

                  # Set rate
                  if activity["DurationInHourRealized"].blank? or activity["AmountRealized"].blank?
                    rate = nil
                  else
                    rate = (activity["AmountRealized"].to_f / activity["DurationInHourRealized"].to_f).round(2)
                  end

                  activity_hash = Hash.new
                  activity_hash[:original_id]     = activity["RequestID"]
                  activity_hash[:customer_id]     = customer_id
                  activity_hash[:unbillable_id]   = nil
                  activity_hash[:user_id]         = user_id
                  activity_hash[:company_id]      = company_id
                  activity_hash[:projectuser_id]  = projectuser_id
                  activity_hash[:project_id]      = project_id
                  activity_hash[:activity_date]   = activity["StartDate"].to_date.strftime("%d%m%Y").to_i
                  activity_hash[:hours]           = get_hours(activity)
                  activity_hash[:rate]            = rate

                  Dwh::EtlStorage.create(account_id: account.id, identifier: "activities", etl: "transform", data: activity_hash)
                end
              end
            end
          end

          ### Extract unbillable activities

          # Send the API GET request as long as the SkipToken is not empty (pagination)
          dim_unbillables = Dwh::DimUnbillable.where(account_id: dim_account.id).where.not(original_id: ["10", "11", "1060006", "LEEGLOOP", "INTERN", "ZIEK_GED_HERST"])
          unless dim_unbillables.blank?
            dim_unbillables.each do |dim_unbillable|
              request_type = dim_unbillable.original_id
              next_request = true
              skip_token = nil

              while next_request == true
                skip_token = skip_token.blank? ? nil : "&SkipToken=#{skip_token}"

                # Get all activities for month
                activities = send_get_request(api_url, api_key, administration, "Synergy/RequestListFiltered?filter=RequestType eq #{request_type} and StatusDescription ne 'Open' and StatusDescription ne 'Concept' and StatusDescription ne 'Rejected' and ResourceID eq #{dim_user.original_id} and StartDate ge DateTime'#{previous_month_start}' and StartDate le DateTime'#{previous_month_end}'#{skip_token}")

                # Set the next request
                if activities == "CONNECTION ERROR"
                  next_request = true
                elsif activities["SkipToken"] == "" or activities["SkipToken"].blank?
                  next_request = false
                  skip_token = nil
                else
                  next_request = true
                  skip_token = activities["SkipToken"]
                end

                # Iterate activities
                unless activities["Results"].blank?
                  activities["Results"].each do |activity|
                    create_unbillable_activity("unbillable", account, activity, dim_unbillable.original_id)
                  end
                end
              end
            end
          end

          ### Load activities, already because it is needed for sickness hours
          Dwh::Loaders::ActivitiesLoader.new.load_data(account)
        end

        ### Set date patterns for sickness, holiday and maternity leave registrations

        # 1. Completely in month
        # 2. Start before month, end in month
        # 3. Start in month, end after month
        # 4. Start before month, end after month
        # 5. Start in month, no end date
        # 6. Start before month, no end date
        date_patterns = [
          "StartDate ge DateTime'#{previous_month_start}' and EndDate le DateTime'#{previous_month_end}'",
          "StartDate lt DateTime'#{previous_month_start}' and EndDate ge DateTime'#{previous_month_start}' and EndDate le DateTime'#{previous_month_end}'",
          "StartDate ge DateTime'#{previous_month_start}' and StartDate le DateTime'#{previous_month_end}' and EndDate gt DateTime'#{previous_month_end}'",
          "StartDate lt DateTime'#{previous_month_start}' and EndDate gt DateTime'#{previous_month_end}'",
          "StartDate ge DateTime'#{previous_month_start}' and EndDate eq null",
          "StartDate lt DateTime'#{previous_month_start}' and EndDate eq null"
        ]

        ### Extract holiday registrations

        # Iterate users
        dim_users.each do |dim_user|
          # Get holiday registrations for each date pattern
          date_patterns.each do |date_pattern|
            # Send the API GET request as long as the SkipToken is not empty (pagination)
            next_request = true
            skip_token = nil

            while next_request == true
              skip_token = skip_token.blank? ? nil : "&SkipToken=#{skip_token}"

              # Get all holiday registrations for month
              holiday_registrations = send_get_request(api_url, api_key, administration, "Synergy/RequestListFiltered?filter=RequestType eq 10 and DurationInHour lt 0 and ResourceID eq #{dim_user.original_id} and #{date_pattern}#{skip_token}")

              # Set the next request
              if holiday_registrations == "CONNECTION ERROR"
                next_request = true
              elsif holiday_registrations["SkipToken"] == "" or holiday_registrations["SkipToken"].blank?
                next_request = false
                skip_token = nil
              else
                next_request = true
                skip_token = holiday_registrations["SkipToken"]
              end
              
              # Iterate activities
              unless holiday_registrations["Results"].blank?
                holiday_registrations["Results"].each do |holiday_registration|
                  create_holiday_activity(account, dim_user, holiday_registration["RequestID"], holiday_registration["StartDate"], holiday_registration["EndDate"], holiday_registration["DurationInHour"], previous_month_start, previous_month_end)
                end
              end
            end
          end

          ### Load activities
          Dwh::Loaders::ActivitiesLoader.new.load_data(account)
        end

        ### Extract sickness registrations

        # Iterate users
        dim_users.each do |dim_user|
          # Get sickness registrations for each date pattern
          date_patterns.each do |date_pattern|
            # Send the API GET request as long as the SkipToken is not empty (pagination)
            next_request = true
            skip_token = nil

            while next_request == true
              skip_token = skip_token.blank? ? nil : "&SkipToken=#{skip_token}"

              # Get all sickness registrations for month
              sickness_registrations = send_get_request(api_url, api_key, administration, "Synergy/RequestListFiltered?filter=RequestType eq 11 and ResourceID eq #{dim_user.original_id} and #{date_pattern}#{skip_token}")

              # Set the next request
              if sickness_registrations == "CONNECTION ERROR"
                next_request = true
              elsif sickness_registrations["SkipToken"] == "" or sickness_registrations["SkipToken"].blank?
                next_request = false
                skip_token = nil
              else
                next_request = true
                skip_token = sickness_registrations["SkipToken"]
              end
              # Iterate activities
              unless sickness_registrations["Results"].blank?
                sickness_registrations["Results"].each do |sickness_registration|
                  create_sickness_activity(account, dim_user, sickness_registration["RequestID"], sickness_registration["StartDate"], sickness_registration["EndDate"], previous_month_start, previous_month_end)
                end
              end
            end
          end

          ### Load activities, already because it is needed for holiday hours
          Dwh::Loaders::ActivitiesLoader.new.load_data(account)
        end

        ### Extract maternity leave registrations

        # Iterate users
        dim_users.each do |dim_user|
          # Get maternity leave registrations for each date pattern
          date_patterns.each do |date_pattern|
            # Send the API GET request as long as the SkipToken is not empty (pagination)
            next_request = true
            skip_token = nil

            while next_request == true
              skip_token = skip_token.blank? ? nil : "&SkipToken=#{skip_token}"

              # Get all maternity leave registrations for month
              maternity_leave_registrations = send_get_request(api_url, api_key, administration, "Synergy/RequestListFiltered?filter=RequestType eq 1060006 and ResourceID eq #{dim_user.original_id} and #{date_pattern}#{skip_token}")

              # Set the next request
              if maternity_leave_registrations == "CONNECTION ERROR"
                next_request = true
              elsif maternity_leave_registrations["SkipToken"] == "" or maternity_leave_registrations["SkipToken"].blank?
                next_request = false
                skip_token = nil
              else
                next_request = true
                skip_token = maternity_leave_registrations["SkipToken"]
              end

              # Iterate activities
              unless maternity_leave_registrations["Results"].blank?
                maternity_leave_registrations["Results"].each do |maternity_leave_registration|
                  create_maternity_leave_activity(account, dim_user, maternity_leave_registration["RequestID"], maternity_leave_registration["StartDate"], maternity_leave_registration["EndDate"], previous_month_start, previous_month_end)
                end
              end
            end
          end

          ### Load activities, already because it is needed for holiday hours
          Dwh::Loaders::ActivitiesLoader.new.load_data(account)
        end
      end

      # Remove activities of previous month
      if Date.current.day == 1
        Dwh::Tasks::EtlExactActivitiesRemoveTask.perform_later(account.id)
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

  private def unbillable_activity?(activity)
    unbillable_activity = false

    if activity["ProjectNumber"] == "LEEGLOOP"
      unbillable_activity = true
    elsif activity["ProjectNumber"] == "ZIEK_GED_HERST"
      unbillable_activity = true
    elsif activity["ProjectNumber"] == "CERIOS_UREN_INTERN"
      unbillable_activity = true
    elsif unbillable_work_project_numbers.map(&:strip).include?(activity["ProjectNumber"])
      unbillable_activity = true
    end
    
    unbillable_activity
  end

  private def create_unbillable_activity(origin, account, activity, dim_unbillable_original_id = nil)
    # Set user and company
    if activity["ResourceID"].blank?
      user_id = nil
      company_id = nil
    else
      dim_user = Dwh::DimUser.find_by(original_id: activity["ResourceID"].to_s.strip)
      user_id = dim_user.blank? ? nil : dim_user.original_id

      if user_id.blank?
        company_id = nil
      else
        dim_company = Dwh::DimCompany.find_by(id: dim_user.company_id)
        company_id = dim_company.blank? ? nil : dim_company.original_id
      end  
    end

    # Create activity
    unless user_id.blank? or company_id.blank?
      # Determine original_id for unbillable activity
      if origin == "billable"
        case activity["ProjectNumber"]
        when "LEEGLOOP"
          original_id = "LEEGLOOP"
        when "ZIEK_GED_HERST"
          original_id = "ZIEK_GED_HERST"
        else
          original_id = "INTERN"
        end
      else
        original_id = dim_unbillable_original_id
      end

      # Ignore positive hours for holiday, because they are balance hours not real holiday hours      
      hours = get_hours(activity)
      unless original_id == "10" and hours > 0
        # Determine if hours need to be inversed
        if origin == "unbillable" and original_id == "9208"
          hours = get_hours(activity)
        elsif origin == "unbillable"
          hours = get_hours(activity) * -1
        else
          hours = get_hours(activity)
        end

        activity_hash = Hash.new
        activity_hash[:original_id]     = activity["RequestID"]
        activity_hash[:customer_id]     = nil
        activity_hash[:unbillable_id]   = original_id
        activity_hash[:user_id]         = user_id
        activity_hash[:company_id]      = company_id
        activity_hash[:projectuser_id]  = nil
        activity_hash[:project_id]      = nil
        activity_hash[:activity_date]   = activity["StartDate"].to_date.strftime("%d%m%Y").to_i
        activity_hash[:hours]           = hours
        activity_hash[:rate]            = nil

        Dwh::EtlStorage.create(account_id: account.id, identifier: "activities", etl: "transform", data: activity_hash)
      end
    end
  end

  private def create_sickness_activity(account, dim_user, request_id, start_date, end_date, month_start, month_end)
    # Date parse dates
    start_date = Date.parse(start_date) unless start_date.blank?
    end_date = Date.parse(end_date) unless end_date.blank?
    month_start = Date.parse(month_start)
    month_end = Date.parse(month_end)

    # Set start date
    real_start_date = start_date < month_start ? month_start : start_date

    # Set end date
    real_end_date = end_date.blank? || end_date > month_end ? month_end : end_date

    # Iterate days and create activity for each day
    (real_start_date..real_end_date).each do |sickness_date|
      # Get already registered hours for this day
      dim_account = Dwh::DimAccount.find_by(original_id: account.id)
      registered_hours = Dwh::FactActivity.where(account_id: dim_account.id, user_id: dim_user.id, activity_date: sickness_date.to_date.strftime("%d%m%Y").to_i).sum(:hours)

      # Only register weekdays
      if (1..5).include?(sickness_date.wday)
        # Do not register on holidays
        dim_holiday = Dwh::DimHoliday.find_by(account_id: dim_account.id, company_id: dim_user.company_id, holiday_date: sickness_date.to_date.strftime("%d%m%Y").to_i)
        unless dim_holiday.present?
          # Set user and company
          user_id = dim_user.original_id
          dim_company = Dwh::DimCompany.find_by(id: dim_user.company_id)
          company_id = dim_company.blank? ? nil : dim_company.original_id

          # Calculate sickness hours and remaining hours
          sickness_hours = dim_user.contract_hours.blank? ? 0.0 : (8.0 * (dim_user.contract_hours.to_f / 40.0)).round(1)
          remaining_hours = sickness_hours - registered_hours
          remaining_hours = 0 if remaining_hours < 0

          # Create activity
          unless remaining_hours <= 0.0
            activity_hash = Hash.new
            activity_hash[:original_id]     = "#{request_id}#{sickness_date.strftime("%d%m%Y")}"
            activity_hash[:customer_id]     = nil
            activity_hash[:unbillable_id]   = "11"
            activity_hash[:user_id]         = user_id
            activity_hash[:company_id]      = company_id
            activity_hash[:projectuser_id]  = nil
            activity_hash[:project_id]      = nil
            activity_hash[:activity_date]   = sickness_date.to_date.strftime("%d%m%Y").to_i
            activity_hash[:hours]           = remaining_hours
            activity_hash[:rate]            = nil

            Dwh::EtlStorage.create(account_id: account.id, identifier: "activities", etl: "transform", data: activity_hash)
          end
        end
      end
    end
  end

  private def create_holiday_activity(account, dim_user, request_id, start_date, end_date, duration_in_hours, month_start, month_end)
    # Date parse dates
    start_date = Date.parse(start_date) unless start_date.blank?
    end_date = Date.parse(end_date) unless end_date.blank?
    month_start = Date.parse(month_start)
    month_end = Date.parse(month_end)

    # Set start date
    real_start_date = start_date < month_start ? month_start : start_date

    # Set end date
    real_end_date = end_date.blank? || end_date > month_end ? month_end : end_date

    # Get nr of working days in period
    nr_working_days = 0
    (real_start_date..real_end_date).each do |holiday_date|
      if (1..5).include?(holiday_date.wday)
        nr_working_days += 1
      end
    end

    # Get contract hours per day
    contract_hours_per_day = dim_user.contract_hours.blank? ? 8.0 : (8.0 * (dim_user.contract_hours.to_f / 40.0)).round(1)
    
    # Iterate days and create activity for each day
    (real_start_date..real_end_date).each do |holiday_date|
      # Get already registered hours for this day
      dim_account = Dwh::DimAccount.find_by(original_id: account.id)
      registered_hours = Dwh::FactActivity.where(account_id: dim_account.id, user_id: dim_user.id, activity_date: holiday_date.to_date.strftime("%d%m%Y").to_i).sum(:hours)

      # Only register weekdays
      if (1..5).include?(holiday_date.wday)
        # Do not register on holidays
        dim_holiday = Dwh::DimHoliday.find_by(account_id: dim_account.id, company_id: dim_user.company_id, holiday_date: holiday_date.to_date.strftime("%d%m%Y").to_i)
        unless dim_holiday.present?
          # Set user and company
          user_id = dim_user.original_id
          dim_company = Dwh::DimCompany.find_by(id: dim_user.company_id)
          company_id = dim_company.blank? ? nil : dim_company.original_id

          # Calculate remaining hours
          remaining_hours = contract_hours_per_day - registered_hours
          remaining_hours = 0 if remaining_hours < 0

          # Calculate holiday hours
          duration_in_hours_abs = duration_in_hours.to_f * -1
          holiday_hours = duration_in_hours_abs > remaining_hours ? remaining_hours : duration_in_hours_abs

          # Create activity
          unless holiday_hours <= 0.0
            activity_hash = Hash.new
            activity_hash[:original_id]     = "#{request_id}#{holiday_date.strftime("%d%m%Y")}"
            activity_hash[:customer_id]     = nil
            activity_hash[:unbillable_id]   = "10"
            activity_hash[:user_id]         = user_id
            activity_hash[:company_id]      = company_id
            activity_hash[:projectuser_id]  = nil
            activity_hash[:project_id]      = nil
            activity_hash[:activity_date]   = holiday_date.to_date.strftime("%d%m%Y").to_i
            activity_hash[:hours]           = holiday_hours
            activity_hash[:rate]            = nil

            Dwh::EtlStorage.create(account_id: account.id, identifier: "activities", etl: "transform", data: activity_hash)
          end
        end
      end
    end
  end

  private def create_maternity_leave_activity(account, dim_user, request_id, start_date, end_date, month_start, month_end)
    # Date parse dates
    start_date = Date.parse(start_date) unless start_date.blank?
    end_date = Date.parse(end_date) unless end_date.blank?
    month_start = Date.parse(month_start)
    month_end = Date.parse(month_end)

    # Set start date
    real_start_date = start_date < month_start ? month_start : start_date

    # Set end date
    real_end_date = end_date.blank? || end_date > month_end ? month_end : end_date

    # Iterate days and create activity for each day
    (real_start_date..real_end_date).each do |maternity_leave_date|
      # Get already registered hours for this day
      dim_account = Dwh::DimAccount.find_by(original_id: account.id)
      registered_hours = Dwh::FactActivity.where(account_id: dim_account.id, user_id: dim_user.id, activity_date: maternity_leave_date.to_date.strftime("%d%m%Y").to_i).sum(:hours)

      # Only register weekdays
      if (1..5).include?(maternity_leave_date.wday)
        # Do not register on holidays
        dim_holiday = Dwh::DimHoliday.find_by(account_id: dim_account.id, company_id: dim_user.company_id, holiday_date: maternity_leave_date.to_date.strftime("%d%m%Y").to_i)
        unless dim_holiday.present?
          # Set user and company
          user_id = dim_user.original_id
          dim_company = Dwh::DimCompany.find_by(id: dim_user.company_id)
          company_id = dim_company.blank? ? nil : dim_company.original_id

          # Calculate maternity leave hours and remaining hours
          maternity_leave_hours = dim_user.contract_hours.blank? ? 0.0 : (8.0 * (dim_user.contract_hours.to_f / 40.0)).round(1)
          remaining_hours = maternity_leave_hours - registered_hours
          remaining_hours = 0 if remaining_hours < 0

          # Create activity
          unless remaining_hours <= 0.0
            activity_hash = Hash.new
            activity_hash[:original_id]     = "#{request_id}#{maternity_leave_date.strftime("%d%m%Y")}"
            activity_hash[:customer_id]     = nil
            activity_hash[:unbillable_id]   = "1060006"
            activity_hash[:user_id]         = user_id
            activity_hash[:company_id]      = company_id
            activity_hash[:projectuser_id]  = nil
            activity_hash[:project_id]      = nil
            activity_hash[:activity_date]   = maternity_leave_date.to_date.strftime("%d%m%Y").to_i
            activity_hash[:hours]           = remaining_hours
            activity_hash[:rate]            = nil

            Dwh::EtlStorage.create(account_id: account.id, identifier: "activities", etl: "transform", data: activity_hash)
          end
        end
      end
    end
  end

  private def get_hours(activity)
    hours = 0.0

    if activity["DurationInHourRealized"].present? and activity["DurationInHourRealized"].to_f != 0.0
      hours = activity["DurationInHourRealized"].to_f.round(1)
    elsif activity["DurationInHour"].present? and activity["DurationInHour"].to_f != 0.0
      hours = activity["DurationInHour"].to_f.round(1)
    end

    hours
  end
end
