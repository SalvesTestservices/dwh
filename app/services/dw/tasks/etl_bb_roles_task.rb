class Dw::Tasks::EtlBbRolesTask < Dw::Tasks::BaseTask
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
      # Create a record for each role
      Dw::DimRole.upsert({ uid: "mm", role: 'Medewerker', category: 'Medewerker'}, unique_by: [:uid])
      Dw::DimRole.upsert({ uid: "ss", role: 'Subco', category: 'Subco'}, unique_by: [:uid])
      Dw::DimRole.upsert({ uid: "mcm", role: 'Managing consultant', category: 'Medewerker'}, unique_by: [:uid])
      Dw::DimRole.upsert({ uid: "dmm", role: 'Delivery manager', category: 'Medewerker'}, unique_by: [:uid])
      Dw::DimRole.upsert({ uid: "tt", role: 'Trainee', category: 'Trainee'}, unique_by: [:uid])

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
