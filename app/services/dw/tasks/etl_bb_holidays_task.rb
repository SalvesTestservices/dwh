class Dw::Tasks::EtlBbHolidaysTask < Dw::Tasks::BaseTask
  queue_as :default

  def perform(account, run, result, task)
    # Wait for alle dependencies to finish
    all_dependencies_finished = wait_on_dependencies(account, run, task)
    if all_dependencies_finished == false
      Dw::DataPipelineLogger.new.create_log(run.id, "cancelled", "[#{account.name}] Taak [#{task.task_key}] geannuleerd")
      result.update(finished_at: DateTime.now, status: "cancelled")
      return
    end

    begin
      ActsAsTenant.without_tenant do
        # Set year
        year = run.dp_pipeline.year.blank? ? Date.current.year : run.dp_pipeline.year.to_i

        # Get all holidays from QDAT because they have NL and BE holidays
        account = Account.find_by(name: "QDat Holding")
        holidays_nl = account.holidays.where("extract(year from holiday_date) = ? AND country = 'NL'", year)
        holidays_be = account.holidays.where("extract(year from holiday_date) = ? AND country = 'BE'", year)

        # Create holidays for all accounts
        accounts = Account.where.not(name: ["Pallas","Supportbook"])
        accounts.each do |account|
          companies = account.companies.where.not(id: get_excluded_company_ids)
          companies.each do |company|
            holidays = company.regulations == "Nederland" ? holidays_nl : holidays_be
            holidays.each do |holiday|
              holidays_hash = Hash.new
              holidays_hash[:account_id]    = account.id
              holidays_hash[:company_id]    = company.id
              holidays_hash[:holiday_date]  = holiday.holiday_date.strftime("%d%m%Y").to_i
              holidays_hash[:name]          = holiday.name
              holidays_hash[:country]       = holiday.country

              Dw::EtlStorage.create(account_id: account.id, identifier: "holidays", etl: "transform", data: holidays_hash)
            end
          end

          ### Load unbillables

          dim_account = Dw::DimAccount.find_by(original_id: account.id)
          holidays = Dw::EtlStorage.where(account_id: account.id, identifier: "holidays", etl: "transform")
          unless holidays.blank?
            holidays.each do |holiday|
              dim_company = Dw::DimCompany.find_by(account_id: dim_account.id, original_id: holiday.data['company_id'])
              unless dim_company.blank?
                uid = "#{dim_account.id}#{dim_company.id}#{holiday.data['holiday_date']}"
                Dw::DimHoliday.upsert({ uid: uid, account_id: dim_account.id, company_id: dim_company.id, holiday_date: holiday.data['holiday_date'], name: holiday.data['name'], country: holiday.data['country'] }, unique_by: [:uid])
              end
              holiday.destroy
            end
          end
        end
      end

      # Update result
      result.update(finished_at: DateTime.now, status: "finished")
      Dw::DataPipelineLogger.new.create_log(run.id, "success", "[#{account.name}] Finished task [#{task.task_key}] successfully")
    rescue => e
      # Update result to failed if an error occurs
      result.update(finished_at: DateTime.now, status: "failed", error: e.message)
      Dw::DataPipelineLogger.new.create_log(run.id, "alert", "[#{account.name}] Finished task [#{task.task_key}] with error: #{e.message}")
    end
  end
end
