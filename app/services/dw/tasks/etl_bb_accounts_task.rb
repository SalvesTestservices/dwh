class Dw::Tasks::EtlBbAccountsTask < Dw::Tasks::BaseTask
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
      # Extract and load accounts
      ActsAsTenant.without_tenant do
        accounts = Account.where.not(name: ["Pallas","Supportbook"])
        accounts.each do |account|
          Dw::DimAccount.upsert({ original_id: account.id, name: account.name, is_holding: account.is_holding }, unique_by: [:original_id])
        end
        
        # Update result
        result.update(finished_at: DateTime.now, status: "finished")
        Dw::DataPipelineLogger.new.create_log(run.id, "success", "[#{account.name}] Finished task [#{task.task_key}] successfully")        
      end
    rescue => e
      # Update result to failed if an error occurs
      result.update(finished_at: DateTime.now, status: "failed", error: e.message)
      Dw::DataPipelineLogger.new.create_log(run.id, "alert", "[#{account.name}] Finished task [#{task.task_key}] with error: #{e.message}")
    end
  end
end
