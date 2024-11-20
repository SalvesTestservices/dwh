namespace :backbone do
  task run_data_pipelines: :environment do
    dp_pipelines = Dw::DpPipeline.where(status: "active").where.not(frequency: [744, 0])
    unless dp_pipelines.blank?
      dp_pipelines.each do |dp_pipeline|
        # Check if pipeline needs to be run based on frequency
        run_pipeline = false
        current_hour = DateTime.now.hour

        if dp_pipeline.frequency == 1
          run_pipeline = true
        end

        if current_hour == 1 and dp_pipeline.frequency == 24
          run_pipeline = true
        end

        if run_pipeline == true
          Dw::DataPipelineExecutor.perform_later(dp_pipeline)
        end
      end
    end
  end

  task run_monthly_data_pipelines: :environment do
    dp_pipelines = Dw::DpPipeline.where(status: "active", frequency: 744)
    unless dp_pipelines.blank?
      dp_pipelines.each do |dp_pipeline|
        Dw::DataPipelineExecutor.perform_later(dp_pipeline)
      end
    end
  end

end
