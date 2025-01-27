class Dwh::Tasks::EtlBaseAccountsTask < Dwh::Tasks::BaseTask
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
      # Set accounts
      accounts = [
        { id: 1, name: 'QDat', is_holding: false },
        { id: 2, name: 'Salves', is_holding: false },
        { id: 3, name: 'Test Crew IT', is_holding: false },
        { id: 4, name: 'Valori', is_holding: false },
        { id: 5, name: 'Cerios', is_holding: true },
        { id: 6, name: 'TestArchitecten', is_holding: true },
        { id: 7, name: 'JOSF', is_holding: true },
        { id: 8, name: 'Omnext', is_holding: true },
        { id: 9, name: 'Testmanagement', is_holding: true },
        { id: 10, name: 'Supportbook', is_holding: true }
      ]

      # Transform data for upsert_all
      accounts_data = accounts.map do |account|
        {
          original_id: account[:id],
          name: account[:name],
          is_holding: account[:is_holding]
        }
      end

      # Create or update accounts
      Dwh::DimAccount.upsert_all(
        accounts_data,
        unique_by: :original_id,
        update_only: [:name, :is_holding],
        returning: false
      )
        
      # Update result
      result.update(finished_at: DateTime.now, status: "finished")
      Dwh::DataPipelineLogger.new.create_log(run.id, "success", "[#{task_account_name}] Finished task [#{task.task_key}] successfully")        
    rescue => e
      # Update result to failed if an error occurs
      result.update(finished_at: DateTime.now, status: "failed", error: e.message)
      Dwh::DataPipelineLogger.new.create_log(run.id, "alert", "[#{task_account_name}] Finished task [#{task.task_key}] with error: #{e.message}")
    end
  end
end
