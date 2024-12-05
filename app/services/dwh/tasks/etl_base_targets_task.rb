class Dwh::Tasks::EtlBaseTargetsTask < Dwh::Tasks::BaseTask
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
      # Extract company_targets
      ActsAsTenant.without_tenant do
        account     = Account.find(run.account_id)
        dim_account = Dwh::DimAccount.find_by(original_id: account.id)
        companies   = account.companies.where.not(id: get_excluded_company_ids)
        year        = account.company_targets.blank? ? Date.current.year : account.company_targets.order(:year).last.year

        # Iterate companies
        companies.each do |company|
          company_targets = account.company_targets.where(company_id: company.id)

          # Iterate over roles, extract and load company_targets or create empty set
          roles = ["employee", "trainee", "subco"]
          roles.each do |role|
            role_targets = company_targets.where(role: role)
            if role_targets.blank?
              create_empty_company_target_hash(year, account, company.id, role)
            else
              role_targets.each do |role_target|
                company_target_hash = Hash.new
                
                case role_target.role
                when "employee"
                  role_group = "Medewerker"
                when "trainee"
                  role_group = "Trainee"
                when "subco"
                  role_group = "Subco"
                end

                company_target_hash[:original_id]         = role_target.id
                company_target_hash[:company_id]          = role_target.company_id
                company_target_hash[:year]                = role_target.year
                company_target_hash[:month]               = role_target.month
                company_target_hash[:quarter]             = role_target.quarter
                company_target_hash[:role_group]          = role_group
                company_target_hash[:fte]                 = role_target.fte
                company_target_hash[:billable_hours]      = role_target.billable_hours
                company_target_hash[:cost_price]          = role_target.cost_price
                company_target_hash[:bruto_margin]        = convert_to_fractional(role_target.bruto_margin)
                company_target_hash[:target_date]         = Date.new(role_target.year, role_target.month, 1).strftime("%d%m%Y").to_i
                company_target_hash[:workable_hours]      = role_target.workable_hours 
                company_target_hash[:productivity]        = convert_to_fractional(role_target.productivity(false))
                company_target_hash[:hour_rate]           = role_target.hour_rate(false)
                company_target_hash[:turnover]            = role_target.turnover(false)
                company_target_hash[:employee_attrition]  = convert_to_fractional(role_target.employee_attrition)
                company_target_hash[:employee_absence]    = convert_to_fractional(role_target.employee_absence)

                Dwh::EtlStorage.create(account_id: account.id, identifier: "company_targets", etl: "extract", data: company_target_hash)
              end
            end
          end
        end

        # Load company_targets
        unless dim_account.blank?
          company_targets = Dwh::EtlStorage.where(account_id: account.id, identifier: "company_targets", etl: "extract")
          unless company_targets.blank?
            company_targets.each do |company_target|
              dim_company     = Dwh::DimCompany.find_by(account_id: dim_account.id, original_id: company_target.data['company_id'])
              dim_company_id  = dim_company.blank? ? nil : dim_company.id

              unless dim_company_id.blank?
                case company_target.data['role_group']
                when "Medewerker"
                  role_group_id = 1
                when "Trainee"
                  role_group_id = 2
                when "Subco"
                  role_group_id = 3
                end

                uid = "#{dim_account.id}#{dim_company.id}#{company_target.data['year']}#{company_target.data['month']}#{company_target.data['quarter']}#{role_group_id}"

                Dwh::FactTarget.upsert({ uid: uid, account_id: dim_account.id, original_id: company_target.data['original_id'], company_id: dim_company.id, 
                  year: company_target.data['year'], month: company_target.data['month'], quarter: company_target.data['quarter'], role_group: company_target.data['role_group'], 
                  fte: company_target.data['fte'], billable_hours: company_target.data['billable_hours'], cost_price: company_target.data['cost_price'], 
                  bruto_margin: company_target.data['bruto_margin'], target_date: company_target.data['target_date'], workable_hours: company_target.data['workable_hours'],
                  productivity: company_target.data['productivity'], hour_rate: company_target.data['hour_rate'], turnover: company_target.data['turnover'], 
                  employee_attrition: company_target.data['employee_attrition'], employee_absence: company_target.data['employee_absence']}, unique_by: [:uid])
              end
              company_target.destroy
            end
          end
        end

        # Data quality check: row count
        expected  = companies.count * 144 #(4 quarters * 12 months * 3 roles)
        actual    = Dwh::FactTarget.where(account_id: dim_account.id, year: year).count
        perform_quality_check("row_count", run, task, actual, expected, "targets gevuld + leeg")

        # Data quality check: row count for filled and empty targets
        expected_filled = 0
        expected_empty  = 0
        companies.each do |company|
          expected_filled  += company.company_targets.count
          expected_empty   += 144 - company.company_targets.count
        end

        actual_filled = Dwh::FactTarget.where(account_id: dim_account.id, year: year).where.not(billable_hours: nil).count
        perform_quality_check("row_count", run, task, actual_filled, expected_filled, "targets gevuld")
        
        actual_empty = Dwh::FactTarget.where(account_id: dim_account.id, year: year).where(billable_hours: nil).count
        perform_quality_check("row_count", run, task, actual_empty, expected_empty, "targets leeg")

        # Update result
        result.update(finished_at: DateTime.now, status: "finished")
        Dwh::DataPipelineLogger.new.create_log(run.id, "success", "[#{account.name}] Finished task [#{task.task_key}] successfully")
      end
    rescue => e
      # Update result to failed if an error occurs
      result.update(finished_at: DateTime.now, status: "failed", error: e.message)
      Dwh::DataPipelineLogger.new.create_log(run.id, "alert", "[#{account.name}] Finished task [#{task.task_key}] with error: #{e.message}")
    end
  end

  private def create_empty_company_target_hash(year, account, company_id, role)
    (1..4).each do |quarter|
      (1..12).each do |month|
        company_target_hash = Hash.new

        case role
        when "employee"
          role_group = "Medewerker"
        when "trainee"
          role_group = "Trainee"
        when "subco"
          role_group = "Subco"
        end
    
        company_target_hash[:original_id]         = (Time.now.to_f * 1000).to_i
        company_target_hash[:company_id]          = company_id
        company_target_hash[:year]                = year
        company_target_hash[:month]               = month
        company_target_hash[:quarter]             = quarter
        company_target_hash[:role_group]          = role_group
        company_target_hash[:fte]                 = nil
        company_target_hash[:billable_hours]      = nil
        company_target_hash[:cost_price]          = nil
        company_target_hash[:bruto_margin]        = nil
        company_target_hash[:target_date]         = Date.new(year, month, 1).strftime("%d%m%Y").to_i
        company_target_hash[:workable_hours]      = nil
        company_target_hash[:productivity]        = nil
        company_target_hash[:hour_rate]           = nil
        company_target_hash[:turnover]            = nil
        company_target_hash[:employee_attrition]  = nil
        company_target_hash[:employee_absence]    = nil
    
        Dwh::EtlStorage.create(account_id: account.id, identifier: "company_targets", etl: "extract", data: company_target_hash)
      end
    end
  end
end
