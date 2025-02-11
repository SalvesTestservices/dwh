class Dwh::Tasks::EtlBaseTargetsTask < Dwh::Tasks::BaseTask
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
      year = Date.current.year
      dim_accounts = Dwh::DimAccount.all
      unless dim_accounts.blank?
        dim_accounts.each do |dim_account|
          companies               = Dwh::DimCompany.where(account_id: dim_account.id)
          account_data_targets    = DataTarget.where(account_id: dim_account.id)

          # Iterate companies
          unless companies.blank?
            dump "HUH1"
            companies.each do |company|
              data_targets = DataTarget.where(account_id: dim_account.id, company_id: company.id, year: year)

              # Iterate over roles, extract and load company_targets or create empty set
              roles = ["employee", "trainee", "subco"]
              roles.each do |role|
                role_targets = data_targets.where(role: role)
                if role_targets.blank?
                  dump "HUH1"
                  create_empty_data_target_hash(year, dim_account, company.id, role)
                else
                  dump "HUH2"
                  role_targets.each do |role_target|
                    data_target_hash = Hash.new
                    
                    case role_target.role
                    when "employee"
                      role_group = "Medewerker"
                    when "trainee"
                      role_group = "Trainee"
                    when "subco"
                      role_group = "Subco"
                    end

                    data_target_hash[:original_id]         = role_target.id
                    data_target_hash[:company_id]          = role_target.company_id
                    data_target_hash[:year]                = role_target.year
                    data_target_hash[:month]               = role_target.month
                    data_target_hash[:quarter]             = role_target.quarter
                    data_target_hash[:role_group]          = role_group
                    data_target_hash[:fte]                 = role_target.fte
                    data_target_hash[:billable_hours]      = role_target.billable_hours
                    data_target_hash[:cost_price]          = role_target.cost_price
                    data_target_hash[:bruto_margin]        = convert_to_fractional(role_target.bruto_margin)
                    data_target_hash[:target_date]         = Date.new(role_target.year, role_target.month, 1).strftime("%d%m%Y").to_i
                    data_target_hash[:workable_hours]      = role_target.workable_hours 
                    data_target_hash[:productivity]        = convert_to_fractional(role_target.productivity(false))
                    data_target_hash[:hour_rate]           = role_target.hour_rate(false)
                    data_target_hash[:turnover]            = role_target.turnover(false)
                    data_target_hash[:employee_attrition]  = convert_to_fractional(role_target.employee_attrition)
                    data_target_hash[:employee_absence]    = convert_to_fractional(role_target.employee_absence)
                    dump "HUH3 #{data_target_hash}"
                    Dwh::EtlStorage.create(account_id: dim_account.id, identifier: "data_targets", etl: "extract", data: data_target_hash)
                  end
                end
              end
            end
          end

          # Load company_targets
          unless dim_account.blank?
            data_targets = Dwh::EtlStorage.where(account_id: dim_account.id, identifier: "data_targets", etl: "extract")
            unless data_targets.blank?
              data_targets.each do |data_target|
                dim_company     = Dwh::DimCompany.find(data_target.data['company_id'])
                dim_company_id  = dim_company.blank? ? nil : dim_company.id

                unless dim_company_id.blank?
                  case data_target.data['role_group']
                  when "Medewerker"
                    role_group_id = 1
                  when "Trainee"
                    role_group_id = 2
                  when "Subco"
                    role_group_id = 3
                  end

                  uid = "#{dim_account.id}#{dim_company.id}#{data_target.data['year']}#{data_target.data['month']}#{data_target.data['quarter']}#{role_group_id}"

                  Dwh::FactTarget.upsert({ uid: uid, account_id: dim_account.id, original_id: data_target.data['original_id'], company_id: dim_company.id, 
                    year: data_target.data['year'], month: data_target.data['month'], quarter: data_target.data['quarter'], role_group: data_target.data['role_group'], 
                    fte: data_target.data['fte'], billable_hours: data_target.data['billable_hours'], cost_price: data_target.data['cost_price'], 
                    bruto_margin: data_target.data['bruto_margin'], target_date: data_target.data['target_date'], workable_hours: data_target.data['workable_hours'],
                    productivity: data_target.data['productivity'], hour_rate: data_target.data['hour_rate'], turnover: data_target.data['turnover'], 
                    employee_attrition: data_target.data['employee_attrition'], employee_absence: data_target.data['employee_absence']}, unique_by: [:uid])
                end
                data_target.destroy
              end
            end
          end
        end

        # Data quality check: row count
        companies = Dwh::DimCompany.all
        expected  = companies.count * 144 #(4 quarters * 12 months * 3 roles)
        actual    = Dwh::FactTarget.where(year: year).count
        perform_quality_check("row_count", run, task, actual, expected, "targets gevuld + leeg")

        # Data quality check: row count for filled and empty targets
        expected_filled = 0
        expected_empty  = 0
        companies.each do |company|
          expected_filled  += DataTarget.where(company_id: company.id, year: year).count
          expected_empty   += 144 - DataTarget.where(company_id: company.id, year: year).count
        end

        actual_filled = Dwh::FactTarget.where(year: year).where.not(billable_hours: nil).count
        perform_quality_check("row_count", run, task, actual_filled, expected_filled, "targets gevuld")
        
        actual_empty = Dwh::FactTarget.where(year: year).where(billable_hours: nil).count
        perform_quality_check("row_count", run, task, actual_empty, expected_empty, "targets leeg")

        # Update result
        result.update(finished_at: DateTime.now, status: "finished")
        Dwh::DataPipelineLogger.new.create_log(run.id, "success", "[#{task_account_name}] Finished task [#{task.task_key}] successfully")
      end
    rescue => e
      # Update result to failed if an error occurs
      result.update(finished_at: DateTime.now, status: "failed", error: e.message)
      Dwh::DataPipelineLogger.new.create_log(run.id, "alert", "[#{task_account_name}] Finished task [#{task.task_key}] with error: #{e.message}")
    end
  end

  private def create_empty_data_target_hash(year, account, company_id, role)
    (1..4).each do |quarter|
      (1..12).each do |month|
        data_target_hash = Hash.new

        case role
        when "employee"
          role_group = "Medewerker"
        when "trainee"
          role_group = "Trainee"
        when "subco"
          role_group = "Subco"
        end
    
        data_target_hash[:original_id]         = (Time.now.to_f * 1000).to_i
        data_target_hash[:company_id]          = company_id
        data_target_hash[:year]                = year
        data_target_hash[:month]               = month
        data_target_hash[:quarter]             = quarter
        data_target_hash[:role_group]          = role_group
        data_target_hash[:fte]                 = nil
        data_target_hash[:billable_hours]      = nil
        data_target_hash[:cost_price]          = nil
        data_target_hash[:bruto_margin]        = nil
        data_target_hash[:target_date]         = Date.new(year, month, 1).strftime("%d%m%Y").to_i
        data_target_hash[:workable_hours]      = nil
        data_target_hash[:productivity]        = nil
        data_target_hash[:hour_rate]           = nil
        data_target_hash[:turnover]            = nil
        data_target_hash[:employee_attrition]  = nil
        data_target_hash[:employee_absence]    = nil
    
        Dwh::EtlStorage.create(account_id: account.id, identifier: "data_targets", etl: "extract", data: data_target_hash)
      end
    end
  end
end
