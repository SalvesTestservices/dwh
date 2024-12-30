namespace :dwh do
  task run_hourly_data_pipelines: :environment do
    dp_pipelines = Dw::DpPipeline.where(status: "active", run_frequency: "hourly")
    unless dp_pipelines.blank?
      dp_pipelines.each do |dp_pipeline|
        Dw::DataPipelineExecutor.perform_later(dp_pipeline)
      end
    end
  end

  task run_daily_data_pipelines: :environment do
    dp_pipelines = Dw::DpPipeline.where(status: "active", run_frequency: "daily")
    unless dp_pipelines.blank?
      dp_pipelines.each do |dp_pipeline|
        Dw::DataPipelineExecutor.perform_later(dp_pipeline)
      end
    end
  end

  task run_monthly_data_pipelines: :environment do
    dp_pipelines = Dw::DpPipeline.where(status: "active", run_frequency: "monthly")
    unless dp_pipelines.blank?
      dp_pipelines.each do |dp_pipeline|
        Dw::DataPipelineExecutor.perform_later(dp_pipeline)
      end
    end
  end

end
