module Datalab
  class DesignerController < ApplicationController
    before_action :authenticate_user!
    before_action :set_datalab_report

    before_action -> { authorize!(:write, :datalab) }
    
    def show
      anchor = Datalab::AnchorRegistry.get_anchor(@datalab_report.anchor_type)
      @available_attributes = anchor[:service].available_attributes

      @breadcrumbs = []
      @breadcrumbs << [I18n.t('.datalab.report.titles.index'), datalab_reports_path]  
      @breadcrumbs << [@datalab_report.name, datalab_report_path(@datalab_report)]
      @breadcrumbs << [I18n.t('.datalab.report.titles.edit')]
    end

    def update
      @datalab_report.update!(column_config: params.require(:column_config))
      head :ok
    end

    private def set_datalab_report
      @datalab_report = DatalabReport.find(params[:id])
    end

    private def designer_params
      params.require(:datalab_report).permit(column_config: {})
    end
  end
end