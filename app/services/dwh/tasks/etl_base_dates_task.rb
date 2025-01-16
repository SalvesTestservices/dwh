class Dwh::Tasks::EtlBaseDatesTask < Dwh::Tasks::BaseTask
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
      year        = run.dp_pipeline.year.blank? ? Date.current.year : run.dp_pipeline.year.to_i
      month       = run.dp_pipeline.month.blank? ? Date.current.month : run.dp_pipeline.month.to_i

      # Fetch holidays for both countries at the start
      nl_holidays = fetch_holidays(year, 'NL').map { |h| Date.parse(h['date']) }
      be_holidays = fetch_holidays(year, 'BE').map { |h| Date.parse(h['date']) }

      existing_dates = Dwh::DimDate.find_by(year: year, month: month)
      if existing_dates.blank?
        # Extract dates
        dates = Array.new
        last_day_of_month = DateTime.new(year, month, 1).end_of_month.day
    
        (1..last_day_of_month).each do |day|
          date = Date.new(year, month, day)
          datetime = DateTime.new(year, month, day)
    
          day_hash = Hash.new
          day_hash[:id]               = date.strftime("%d%m%Y").to_i
          day_hash[:original_date]    = date
          day_hash[:year]             = year
          day_hash[:month]            = month
          day_hash[:yearmonth]        = date.strftime("%Y%m").to_i
          day_hash[:iso_year]         = date.strftime("%G").to_i
          day_hash[:iso_week]         = date.strftime("%V").to_i
          day_hash[:month_name]       = I18n.t(".data_target.date.month_names")[month]
          day_hash[:month_name_short] = I18n.t(".data_target.date.abbr_month_names")[month]
          day_hash[:day]              = day
          day_hash[:day_of_week]      = datetime.wday
          day_hash[:day_name]         = I18n.t(".data_target.date.day_names")[datetime.wday]
          day_hash[:day_name_short]   = I18n.t(".data_target.date.abbr_day_names")[datetime.wday]
          day_hash[:quarter]          = (date.month - 1) / 3 + 1
          day_hash[:week_nr]          = date.cweek
    
          if date.saturday? or date.sunday?
            day_hash[:is_workday] = false
          else
            day_hash[:is_workday] = true
          end
          day_hash[:is_holiday_nl] = nl_holidays.include?(date)
          day_hash[:is_holiday_be] = be_holidays.include?(date)
    
          Dwh::EtlStorage.create(account_id: task_account_id, identifier: "dates", etl: "extract", data: day_hash)
        end

        # Load dates
        dates = Dwh::EtlStorage.where(identifier: "dates", etl: "extract")
        unless dates.blank?
          dates.each do |date|
            dim_date = Dwh::DimDate.find_by(id: date.data['id'])
            if dim_date.blank?
              Dwh::DimDate.find_or_create_by(id: date.data['id']) do |dim_date|
                dim_date.original_date = date.data['original_date']
                dim_date.year = date.data['year']
                dim_date.month = date.data['month']
                dim_date.yearmonth = date.data['yearmonth']
                dim_date.iso_year = date.data['iso_year']
                dim_date.iso_week = date.data['iso_week']
                dim_date.month_name = date.data['month_name']
                dim_date.month_name_short = date.data['month_name_short']
                dim_date.day = date.data['day']
                dim_date.day_of_week = date.data['day_of_week']
                dim_date.day_name = date.data['day_name']
                dim_date.day_name_short = date.data['day_name_short']
                dim_date.quarter = date.data['quarter']
                dim_date.week_nr = date.data['week_nr']
                dim_date.is_workday = date.data['is_workday']
                dim_date.is_holiday_nl = date.data['is_holiday_nl']
                dim_date.is_holiday_be = date.data['is_holiday_be']
              end
            end
            date.destroy
          end
        end
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

  private def fetch_holidays(year, country_code)
    cache_key = "holidays/#{country_code}/#{year}"
    
    Rails.cache.fetch(cache_key, expires_in: 1.week) do
      response = HTTParty.get("https://date.nager.at/api/v3/PublicHolidays/#{year}/#{country_code}")
      
      unless response.success?
        Rails.logger.error("Failed to fetch holidays for #{country_code}: #{response.body}")
        return []
      end
      
      response.parsed_response
    rescue HTTParty::Error => e
      Rails.logger.error("HTTParty error fetching holidays: #{e.message}")
      []
    rescue StandardError => e
      Rails.logger.error("Error fetching holidays: #{e.message}")
      []
    end
  end

end
