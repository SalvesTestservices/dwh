class Dw::DataPipelineLogger
  def initialize
  end

  def create_log(run_id, status, message)
    Dw::DpLog.create(dp_run_id: run_id, status: status, message: "[#{DateTime.now.strftime("%H:%M:%S")}]#{message}")
  end
end