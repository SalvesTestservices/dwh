class Dwh::Tasks::EtlBbCustomersTask < Dwh::Tasks::BaseTask
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
      # Extract customers
      ActsAsTenant.without_tenant do
        account   = Account.find(run.account_id)
        dim_account = Dwh::DimAccount.find_by(original_id: account.id)
        customers = account.customers  
        unless customers.blank?
          customers.each do |customer|
            customers_hash = Hash.new
            customers_hash[:original_id]  = customer.id
            customers_hash[:name]         = customer.name
            customers_hash[:status]       = customer.status
            customers_hash[:updated_at]   = customer.updated_at.strftime("%d%m%Y").to_i
  
            Dwh::EtlStorage.create(account_id: account.id, identifier: "customers", etl: "transform", data: customers_hash)
          end
        end

        # Load customers
        Dwh::Loaders::CustomersLoader.new.load_data(account)

        # Data quality check: row count
        expected    = account.customers.count
        actual      = Dwh::DimCustomer.where(account_id: dim_account.id).count
        perform_quality_check("row_count", run, task, actual, expected)
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
