namespace :dwh do
  task import_targets: :environment do
    require 'roo'

    if ENV['YEAR'].blank?
      puts "Please provide a year! Example: rake dw:import_targets_in_backbone YEAR=2024"    
    else
      year = ENV['YEAR'].to_i
      scoped_account_name = ENV['ACCOUNT_NAME']
      workbook = Roo::Excelx.new(Rails.root.join("db", "dwh_data", "targets_#{year}.xlsx"))

      # Iterate over each sheet in the workbook
      workbook.sheets.each do |sheet|
        # Get account and company
        account_name, company_name = sheet.split(' - ')
        account = Dwh::DimAccount.find_by(name: account_name)
        company = Dwh::DimCompany.find_by(name_short: company_name)

        # If scoped_account_name is present and it doesn't match the current account.name, skip this iteration
        next if scoped_account_name.present? && account.name.downcase != scoped_account_name.downcase

        unless account.blank? or company.blank?
          workbook.sheet(sheet).each_row_streaming(offset: 2) do |row|
            unless row[0].blank?
              # Set role
              case row[0].value.downcase
              when "medewerker"
                role = "employee"
              when "trainee"
                role = "trainee"
              when "subco"
                role = "subco"
              end

              # Set values
              month               = row[2].value.to_i
              fte                 = row[3].value.to_f.round(1)
              billable_hours      = row[4].value.to_f.round(0)
              bruto_margin        = (row[5].value.to_s.gsub("%","").to_f*100).round(2)
              cost_price          = row[6].value.to_f.round(2)
              employee_attrition  = 4.0
              employee_absence    = 4.0

              (1..4).each do |quarter|
                target = DataTarget.find_by(account_id: account.id, company_id: company.id, year: year, month: month, quarter: quarter, role: role)
                if target.blank?
                  DataTarget.create!(account_id: account.id, company_id: company.id, quarter: quarter, year: year, month: month, role: role, fte: fte, billable_hours: billable_hours, bruto_margin: bruto_margin, cost_price: cost_price, employee_attrition: employee_attrition, employee_absence: employee_absence)
                else
                  target.update!(fte: fte, billable_hours: billable_hours, bruto_margin: bruto_margin, cost_price: cost_price, employee_attrition: employee_attrition, employee_absence: employee_absence)
                end
              end
            end
          end
        end
      end
    end
  end
  
  task create_dim_dates: :environment do
    ActsAsTenant.without_tenant do
      account     = Account.find(4) # Use QDAT because of Belgian holidays

      if ENV['START_YEAR'].blank? or ENV['END_YEAR'].blank?
        puts "Please provide a start and end year. Example: rake dw:create_dim_dates START_YEAR=2018 END_YEAR=2020"
      else
        (ENV['START_YEAR'].to_i..ENV['END_YEAR'].to_i).each do |year|
          (1..12).each do |month|
            existing_dates = Dw::DimDate.find_by(year: year, month: month)
            if existing_dates.blank?
              # Extract dates
              dates = Array.new
              last_day_of_month = DateTime.new(year, month, 1).end_of_month.day
          
              (1..last_day_of_month).each do |day|
                date = Date.new(year, month, day)
                datetime = DateTime.new(year, month, day)
      
                Dw::DimDate.find_or_create_by(id: date.strftime("%d%m%Y").to_i) do |dim_date|
                  dim_date.original_date = date
                  dim_date.year = year
                  dim_date.month = month
                  dim_date.yearmonth = date.strftime("%Y%m").to_i
                  dim_date.iso_year = date.strftime("%G").to_i
                  dim_date.iso_week = date.strftime("%V").to_i
                  dim_date.month_name = I18n.t("date.month_names")[month]
                  dim_date.month_name_short = I18n.t("date.abbr_month_names")[month]
                  dim_date.day = day
                  dim_date.day_of_week = datetime.wday
                  dim_date.day_name = I18n.t("date.day_names")[datetime.wday]
                  dim_date.day_name_short = I18n.t("date.abbr_day_names")[datetime.wday]
                  dim_date.quarter = (date.month - 1) / 3 + 1
                  dim_date.week_nr = date.cweek

                  if date.saturday? or date.sunday?
                    dim_date.is_workday = false
                  else
                    dim_date.is_workday = true
                  end
            
                  dim_date.is_holiday_nl = account.holidays.find_by(holiday_date: date, country: "NL").blank? ? false : true
                  dim_date.is_holiday_be = account.holidays.find_by(holiday_date: date, country: "BE").blank? ? false : true
                end
              end
            end
          end
        end
      end
    end
  end

  task check_diffs: :environment do
    ActsAsTenant.without_tenant do
      if ENV['MONTH'].blank? or ENV['YEAR'].blank?
        puts "Please provide a month and year. Example: rake dw:check_diffs MONTH=2 YEAR=2024"
      else
        year = ENV['YEAR'].to_i
        month = ENV['MONTH'].to_i

        accounts = Account.all
        accounts.each do |account|
          companies = account.companies
          companies.each do |company|
            dim_account = Dw::DimAccount.find_by(original_id: account.id)
            dim_company = Dw::DimCompany.find_by(original_id: company.id)

            unless dim_account.blank? or dim_company.blank?
              # Convert year and month to strings
              year_str = year.to_s
              month_str = month.to_s.rjust(2, '0') # Pad with leading zero if month is a single digit
              
              fact_activities = Dw::FactActivity.where(account_id: dim_account.id, company_id: dim_company.id, unbillable_id: nil).select do |activity|
                # Convert activity_date to string and extract year and month parts
                activity_date_str = activity.activity_date.to_s
                activity_year = activity_date_str[4..7]
                activity_month = activity_date_str[2..3]
              
                activity_year == year_str && activity_month == month_str
              end
              fact_activities_count = fact_activities.count.to_s.rjust(4, ' ')
              fact_activity_hours = fact_activities.sum { |activity| activity.hours }.to_s.rjust(5, ' ')

              user_ids = company.users.pluck(:id)
              timesheet_ids = Timesheet.where(month: month, year: year, user_id: user_ids).pluck(:id)
              activities = Activity.where(timesheet_id: timesheet_ids, unbillable_id: nil)


              puts "DWH NR #{fact_activities_count}|DWH HOURS #{fact_activities_hours}|BB NR #{activities.count}|BB HOURS #{activities.sum(:hours)}|COMPANY: #{company.name}"
            end
          end
        end
      end
    end
  end
end