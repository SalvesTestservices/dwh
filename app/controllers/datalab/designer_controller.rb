module Datalab
  class DesignerController < ApplicationController
    before_action :set_datalab_report
    
    def show
      anchor = Datalab::AnchorRegistry.get_anchor(@datalab_report.anchor_type)
      @available_attributes = anchor[:service].available_attributes
    end

    def update
      if @datalab_report.update(designer_params)
        head :ok
      else
        head :unprocessable_entity
      end
    end

    private def set_datalab_report
      @datalab_report = DatalabReport.find(params[:id])
    end

    private def designer_params
      params.require(:datalab_report).permit(column_config: {})
    end
  end
end