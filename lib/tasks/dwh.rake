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
  
  task duplicate_pipeline: :environment do
    if ENV['SOURCE_PIPELINE_ID'].blank?
      puts "NO SOURCE PIPELINE ID PROVIDED!"
    else
      # Get the source pipeline and duplicate it
      source_pipeline = Dwh::DpPipeline.find(ENV['SOURCE_PIPELINE_ID'])
      target_pipeline = Dwh::DpPipeline.create!(name: source_pipeline.name, status: source_pipeline.status, run_frequency: source_pipeline.run_frequency,
          load_method: source_pipeline.load_method, account_id: source_pipeline.account_id, pipeline_key: "temp")

      # Duplicate all tasks from source to target pipeline
      source_pipeline.dp_tasks.each do |task|
        target_pipeline.dp_tasks.create!(
          task.attributes
            .except('id', 'created_at', 'updated_at', 'pipeline_id')
        )
      end
    end
  end
end