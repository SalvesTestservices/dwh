class Dwh::Tasks::EtlBaseRolesTask < Dwh::Tasks::BaseTask
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
      # Create a record for each role
      Dwh::DimRole.upsert({ uid: "mm", role: 'Medewerker', category: 'Medewerker'}, unique_by: [:uid])
      Dwh::DimRole.upsert({ uid: "ss", role: 'Subco', category: 'Subco'}, unique_by: [:uid])
      Dwh::DimRole.upsert({ uid: "mcm", role: 'Managing consultant', category: 'Medewerker'}, unique_by: [:uid])
      Dwh::DimRole.upsert({ uid: "dmm", role: 'Delivery manager', category: 'Medewerker'}, unique_by: [:uid])
      Dwh::DimRole.upsert({ uid: "tt", role: 'Trainee', category: 'Trainee'}, unique_by: [:uid])

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
