class Dw::DataPipelineExecutor < ApplicationJob
  queue_as :default

  def perform(dp_pipeline)
    result_ids = Array.new

    # Remove old runs (including results and logs)
    dp_pipeline.dp_runs.where('created_at < ?', 3.days.ago).destroy_all

    # Iterate all accounts
    unless dp_pipeline.account_ids.blank?
      dp_pipeline.account_ids.each do |account_id|
        account = Account.find(account_id.to_i)

        # Create a new run for the account
        run = Dw::DpRun.create(account_id: account.id, status: "started", started_at: DateTime.now, dp_pipeline_id: dp_pipeline.id)

        Dw::DataPipelineLogger.new.create_log(run.id, "success", "[#{account.name}] Run gestart")

        # Get all pipeline tasks, iterate and run
        tasks = dp_pipeline.dp_tasks.active.order(:sequence)
        tasks.each do |task|
          # Create a new result to store the dependencies
          result = Dw::DpResult.create!(dp_run_id: run.id, dp_task_id: task.id, depends_on: task.depends_on, started_at: DateTime.now, status: "started")
          result_ids << result.id

          Dw::DataPipelineLogger.new.create_log(run.id, "success", "[#{account.name}] Taak [#{task.task_key}] gestart")

          # Execute the task by finding the class and running it
          task_class = class_eval("Dw::Tasks::#{task.task_key.split('_').map(&:capitalize).join}Task")
          job = task_class.perform_later(account, run, result, task)

          # Save the job ID
          result.update(job_id: job.job_id)
        end

        # Check if all jobs of run are finished
        Dw::DataPipelineChecker.perform_later(account, run, result_ids)
      end
    end
  end
end