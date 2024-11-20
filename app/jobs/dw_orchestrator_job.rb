class DwOrchestratorJob < ApplicationJob
  queue_as :default

  def perform(year, month, etl_load_method)
    Dw::Orchestrator.new(year, month, etl_load_method).etl_data
  end
end
