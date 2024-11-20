class Dw::Tasks::EtlBbUnbillablesTask < Dw::Tasks::BaseTask
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
      # Extract unbillables
      ActsAsTenant.without_tenant do
        account     = Account.find(run.account_id)
        dim_account = Dw::DimAccount.find_by(original_id: account.id)
        unbillables = account.unbillables
        unless unbillables.blank?
          unbillables.each do |unbillable|
            unbillables_hash = Hash.new
            unbillables_hash[:original_id]  = unbillable.id
            unbillables_hash[:name]         = unbillable.name
            unbillables_hash[:name_short]   = unbillable.name_short
            unbillables_hash[:updated_at]   = unbillable.updated_at.strftime("%d%m%Y").to_i
  
            Dw::EtlStorage.create(account_id: account.id, identifier: "unbillables", etl: "transform", data: unbillables_hash)
          end
        end

        # Load unbillables
        Dw::Loaders::UnbillablesLoader.new.load_data(account)

        # Data quality check: row count
        expected    = account.unbillables.count
        actual      = Dw::DimUnbillable.where(account_id: dim_account.id).count
        perform_quality_check("row_count", run, task, actual, expected)
        
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
