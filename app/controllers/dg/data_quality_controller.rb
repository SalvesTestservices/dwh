class Dg::DataQualityController < ApplicationController
  include ActionView::Helpers::TagHelper

  before_action :authenticate_user!
  before_action -> { authorize!(:read, :data_governance) }, only: [:index]

  def index
  end

  def read
    dg_quality_log = Dwh::DgQualityLog.find(params[:data_quality_id])
    dg_quality_log.update(read_at: Time.current)
    
    remaining_logs = Dwh::DgQualityLog.where(read_at: nil)
    
    if remaining_logs.empty?
      render turbo_stream: [
        turbo_stream.update('data_quality_logs_list', 
          content_tag(:li, class: 'flex items-center justify-center px-3 py-6') do
            content_tag(:div, I18n.t('.data_quality.messages.no_logs'), 
                       class: 'text-base leading-6 text-gray-900')
          end
        )
      ]
    else
      render turbo_stream: [
        turbo_stream.remove(dg_quality_log)
      ]
    end
  end
end