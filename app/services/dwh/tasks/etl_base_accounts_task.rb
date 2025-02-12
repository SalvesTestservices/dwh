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
        { id: 1, original_id: 4, name: 'QDat', is_holding: false, administration_globe: nil, administration_synergy: nil },
        { id: 2, original_id: 2, name: 'Salves', is_holding: false, administration_globe: nil, administration_synergy: nil },
        { id: 3, original_id: 6, name: 'Test Crew IT', is_holding: false, administration_globe: nil, administration_synergy: nil },
        { id: 4, original_id: 8, name: 'Valori', is_holding: false, administration_globe: "735376G001P", administration_synergy: "735376S001P" },
        { id: 5, original_id: 1, name: 'Cerios', is_holding: true, administration_globe: nil, administration_synergy: nil },
        { id: 6, original_id: 9, name: 'TestArchitecten', is_holding: false, administration_globe: nil, administration_synergy: nil },
        { id: 7, original_id: 10, name: 'JOSF', is_holding: false, administration_globe: nil, administration_synergy: nil },
        { id: 8, original_id: 11, name: 'Omnext', is_holding: false, administration_globe: nil, administration_synergy: nil },
        { id: 9, original_id: 12, name: 'Testmanagement', is_holding: false, administration_globe: nil, administration_synergy: nil },
        { id: 10, original_id: 13, name: 'Supportbook', is_holding: false, administration_globe: nil, administration_synergy: nil }
      ]

      # Transform data for upsert_all
      accounts_data = accounts.map do |account|
        {
          id: account[:id],
          original_id: account[:original_id],
          name: account[:name],
          is_holding: account[:is_holding],
          administration_globe: account[:administration_globe],
          administration_synergy: account[:administration_synergy]
        }
      end

      # Create or update accounts
      Dwh::DimAccount.upsert_all(
        accounts_data,
        unique_by: :original_id,
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
