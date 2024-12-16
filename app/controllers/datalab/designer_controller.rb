module Datalab
  class DesignerController < ApplicationController
    before_action :set_report
    
    def show
      anchor = Datalab::AnchorRegistry.get_anchor(@report.anchor_type)
      @available_attributes = anchor[:service].available_attributes
    end

    def update
      if @report.update(designer_params)
        head :ok
      else
        head :unprocessable_entity
      end
    end

    private

    def set_report
      @report = DatalabReport.find(params[:id])
    end

    def designer_params
      params.require(:datalab_report).permit(column_config: {})
    end
  end
end