class Dwh::Tasks::EtlExactUnbillablesTask < Dwh::Tasks::BaseExactTask
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
      # Extract users
      ActsAsTenant.without_tenant do
        account     = Account.find(run.account_id)

        ### Extract unbillables

        unbillables = Array.new
        unbillables << { original_id: "1060007", name: "Bijzonder verlof", name_short: "BV" }
        unbillables << { original_id: "14", name: "Ouderschapsverlof", name_short: "OVB" }
        unbillables << { original_id: "9208", name: "Overige uren", name_short: "U" }
        unbillables << { original_id: "9207", name: "Tijd voor tijd", name_short: "PM" }
        unbillables << { original_id: "10", name: "Vakantie", name_short: "V" }
        unbillables << { original_id: "9213", name: "Verlofopbouw jubileum", name_short: "BV" }
        unbillables << { original_id: "11", name: "Ziekmelding", name_short: "Z" }
        unbillables << { original_id: "1060006", name: "Zwangerschapsverlof", name_short: "BEV" }
        unbillables << { original_id: "LEEGLOOP", name: "Geen opdracht", name_short: "I" }
        unbillables << { original_id: "INTERN", name: "Intern", name_short: "U" }
        unbillables << { original_id: "ZIEK_GED_HERST", name: "Ziek gedeeltelijk herstel", name_short: "RI" }
        
        ### Transform unbillables
        unbillables.each do |unbillable|
          unbillables_hash = Hash.new
          unbillables_hash[:original_id]  = unbillable[:original_id]
          unbillables_hash[:name]         = unbillable[:name]
          unbillables_hash[:name_short]   = unbillable[:name_short]
          unbillables_hash[:updated_at]   = DateTime.now.strftime("%d%m%Y").to_i

          Dwh::EtlStorage.create(account_id: account.id, identifier: "unbillables", etl: "transform", data: unbillables_hash)
        end

        ### Load unbillables
        Dwh::Loaders::UnbillablesLoader.new.load_data(account)
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
