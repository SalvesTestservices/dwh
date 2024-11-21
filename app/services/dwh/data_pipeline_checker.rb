class Dwh::DataPipelineChecker < ApplicationJob
  queue_as :default

  def perform(account, run, result_ids)
    results = Dwh::DpResult.where(id: result_ids)
    job_ids = results.pluck(:job_id)

    # Keep checking jobs until all are finished
    while job_ids.count > 0
      job_ids.each do |job_id|
        # Find the job and reload it
        job = GoodJob::Job.find(job_id)
        job.reload

        # If job is finished or errored, remove it from the list
        if job.finished_at.present?
          job_ids.delete(job_id)
        elsif job.error.present?
          handle_failed_job(job, results)
          job_ids.delete(job_id)
        end
      end
      sleep(5)
    end

    # Determine status if it is not already failed or cancelled
    if all_tasks_finished?(run)
      if run.dp_results.where(status: "finished").count == run.dp_results.count
        status = "finished"
      elsif run.dp_results.where(status: "failed").count > 0
        status = "failed"
      elsif run.dp_results.where(status: "cancelled").count > 0
        status = "cancelled" 
      end
    end

    # Update run and pipeline when all jobs are finished
    run.update(status: status, finished_at: DateTime.now)
    run.dp_pipeline.update(last_executed_at: DateTime.now)

    Dwh::DataPipelineLogger.new.create_log(run.id, "success", "[#{account.name}] Run gereed")
  end

  private def handle_failed_job(failed_job, results)
    failed_result = results.find_by(job_id: failed_job.id)
    failed_task_key = failed_result.dp_task.task_key

    # Update the failed result
    failed_result.update(status: "failed", error: failed_job.error, finished_at: DateTime.now)

    Dwh::DataPipelineLogger.new.create_log(failed_result.dp_run.id, "alert", "Taak [#{failed_task_key}] mislukt: #{failed_job.error}")
    
    # Destroy the failed job
    failed_job.destroy

    # Find and cancel jobs that depend on the failed job
    cancel_dependent_jobs(failed_task_key, results)
  end

  private def cancel_dependent_jobs(failed_task_key, results)
    results.each do |result|
      if result.depends_on.include?(failed_task_key)
        job = GoodJob::Job.find(result.job_id)
        if job.present?
          # Update the result status to "cancelled"
          result.update(status: "cancelled", finished_at: DateTime.now)

          Dwh::DataPipelineLogger.new.create_log(result.dp_run.id, "alert", "Afhankelijke taak [#{result.dp_task.task_key}] geannuleerd")

          # Destroy the job
          job.destroy
  
          # Recursively cancel all dependent jobs
          cancel_dependent_jobs(result.dp_task.task_key, results)
        end
      end
    end
  end

  private def all_tasks_finished?(run)
    all_tasks_finished = true

    run.dp_results.each do |result|
      if result.status == "started"
        all_tasks_finished = false
        break
      end
    end

    all_tasks_finished
  end
end