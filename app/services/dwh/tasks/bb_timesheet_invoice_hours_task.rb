class Dwh::Tasks::BbTimesheetInvoiceHoursTask < Dwh::Tasks::BaseTask
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
      ActsAsTenant.without_tenant do
        years = [1.year.ago.year, Date.current.year]
        accounts = Account.all
        accounts.each do |account|
          companies = account.companies
          unless companies.blank?
            companies.each do |company|
              users = company.users
              unless users.blank?
                users.each do |user|
                  timesheets = account.timesheets.includes(:activities).where("status = 'approved' AND year IN (?) AND user_id = ?", years, user.id)
                  unless timesheets.blank?
                    timesheets.each do |timesheet|
                      projectuser_ids = timesheet.activities.pluck(:projectuser_id).uniq
                      unless projectuser_ids.blank?
                        projectuser_ids.each do |projectuser_id|
                          unless projectuser_id.blank?
                            projectuser = account.projectusers.find(projectuser_id)
                            unless projectuser.selfbilling? or projectuser.project.fixed_price?
                              timesheet_hours = timesheet.activities.where(projectuser_id: projectuser_id).sum(:hours)

                              invoice = account.invoices.includes(:invoice_lines).find_by(timesheet_id: timesheet.id, project_id: projectuser.project_id, credit: timesheet.credit)
                              if invoice.blank?
                                invoice_hours = 0.0
                              else
                                activity = timesheet.activities.where(projectuser_id: projectuser_id).first
                                phourtype = Phourtype.find_by(id: activity.phourtype_id)
                                invoice_hours = 0.0
                                
                                invoice.invoice_lines.each do |il|
                                  if il.description.include?("Inzet")
                                    if phourtype.present? and phourtype.daily_rate.present?
                                      invoice_hours += il.quantity * 8.0
                                    else
                                      invoice_hours += il.quantity
                                    end
                                  end
                                end
                              end
     
                              customer = projectuser.project.customer.blank? ? "-" : projectuser.project.customer.name
                              unless invoice.blank?
                                if timesheet_hours != invoice_hours
                                  uid = "#{account.id}#{timesheet.id}#{invoice.id}".to_i

                                  Dwh::BbTimesheetInvoiceHour.upsert({ uid: uid, month: timesheet.month, year: timesheet.year, account_id: account.id, account_name: account.name,
                                    company_id: company.id, company_name: company.name, user_name: user.full_name, customer_name: customer, timesheet_hours: timesheet_hours, 
                                    invoice_hours: invoice_hours, diff_hours: (invoice_hours - timesheet_hours).round(2) }, unique_by: [:uid])
                                end
                              end
                            end
                          end
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        end
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
end
