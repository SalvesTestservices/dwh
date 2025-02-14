class Dg::DataQualityController < ApplicationController
  before_action :authenticate_user!
  before_action -> { authorize!(:read, :data_governance) }, only: [:index]

  def index
  end

  def read
    dg_quality_log = Dwh::DgQualityLog.find(params[:data_quality_id])
    dg_quality_log.update(read_at: Time.current)
    
    render turbo_stream: [
      turbo_stream.remove(dg_quality_log)
    ]
  end
end