class Dwh::Tasks::EtlLucanetTask < Dwh::Tasks::BaseTask
=begin
  queue_as :default

  class LucanetConnection < ActiveRecord::Base
    self.abstract_class = true
    establish_connection :lucanet
  end

  def perform(account, run, result, task)
    # Wait for all dependencies to finish
    all_dependencies_finished = wait_on_dependencies(account, run, task)
    if all_dependencies_finished == false
      Dwh::DataPipelineLogger.new.create_log(run.id, "cancelled", "[#{account.name}] Taak [#{task.task_key}] geannuleerd")
      result.update(finished_at: DateTime.now, status: "cancelled")
      return
    end

    begin      
      ### 1. Extract data from lucanet      

      facts, periods, adjustment_levels, data_levels, partner_structures, organisation_structures, transaction_type_structures, account_structures = with_lucanet_connection do
        [
          fetch_data_from_lucanet("Facts"),
          fetch_data_from_lucanet("Period"),
          fetch_data_from_lucanet("AdjustmentLevel"),
          fetch_data_from_lucanet("DataLevel"),
          fetch_data_from_lucanet("PartnerStructure"),
          fetch_data_from_lucanet("OrganisationStructure"),
          fetch_data_from_lucanet("TransactionTypeStructure"),
          fetch_data_from_lucanet("AccountStructure")
        ]
      end

      ### 2. Transform and load data
      batch_size = 1000
      facts.each_slice(batch_size) do |batch|
        transformed_facts = batch.map do |fact|
          period = periods.find { |p| p['PeriodID'] == fact['PeriodID'] }
          adjustment_level = adjustment_levels.find { |a| a['AdjustmentLevelID'] == fact['AdjustmentLevelID'] }
          data_level = data_levels.find { |d| d['DataLevelID'] == fact['DataLevelID'] }
          partner_structure = partner_structures.find { |p| p['PartnerStructureID'] == fact['PartnerStructureID'] }
          organisation_structure = organisation_structures.find { |o| o['OrganisationStructureID'] == fact['OrganisationStructureID'] }
          transaction_type_structure = transaction_type_structures.find { |t| t['TransactionTypeStructureID'] == fact['TransactionTypeStructureID'] }
          account_structure = account_structures.find { |a| a['AccountStructureID'] == fact['AccountStructureID'] }

          uid = "#{fact['ReportElementID']}#{fact['DataLevelID']}#{fact['AdjustmentLevelID']}#{fact['PartnerID']}#{fact['TransactionTypeID']}#{fact['OrganisationElementID']}#{fact['PeriodID']}#{fact['StructureTransactionTypeID']}#{fact['Value'].to_i}#{fact['ExportTimestamp']}"

          {
            uid: uid,
            period: period['PeriodID'],
            month: period['Month'],
            year: period['Year'],
            quarter: period['Quarter'],
            currency: fact['DisplayCurrency'],
            amount: fact['Value'],
            export_timestamp: fact['ExportTimestamp'],
            adjustment_level_name: adjustment_level['AdjustmentLevelName'],
            adjustment_level_type: adjustment_level['AdjustmentLevelType'],
            adjustment_level_order: adjustment_level['AdjustmentLevelOrder'],
            data_level_name: data_level['DataLevelName'],
            data_level_type: data_level['DataLevelType'],
            data_level_period_from: data_level['PeriodFrom'],
            data_level_period_to: data_level['PeriodTo'],
            partner_id: fact['PartnerID'],
            partner_name: partner_structure['PartnerName'],
            organisation_element_id: fact['OrganisationElementID'],
            organisation_element_name: organisation_structure['OrganisationName'],
            organisation_accounting_or_consolidation_area: organisation_structure['AccountingOrConsolidationArea'],
            transaction_structure_type_id: fact['StructureTransactionTypeID'],
            transaction_type_name: transaction_type_structure['TransactionTypeName'],
            transaction_type_type: transaction_type_structure['TransactionTypeType'],
            account_report_element_id: fact['ReportElementID'],
            account_name: account_structure['AccountName'],
            account_balance_type: account_structure['BalanceType'],
            account_level_1: account_structure['AccountLevel1'],
            account_level_2: account_structure['AccountLevel2'],
            account_level_3: account_structure['AccountLevel3'],
            account_level_4: account_structure['AccountLevel4'],
            account_level_5: account_structure['AccountLevel5'],
            account_level_6: account_structure['AccountLevel6']
          }
        end
        Dwh::LucanetTransaction.upsert_all(transformed_facts, unique_by: :uid)
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

  private def with_lucanet_connection
    yield
  ensure
    LucanetConnection.connection_pool.disconnect!
  end

  private def fetch_data_from_lucanet(table_name)
    results = LucanetConnection.connection.execute("SELECT * FROM \"#{table_name}\"")
    results.to_a
  end
=end
end