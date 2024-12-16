class Datalab::ReportsController < ApplicationController
  def index
    @reports = DatalabReport.where(user_id: current_user.id)
  end

  def new
    @report = DatalabReport.new
    @available_anchors = AnchorRegistry.available_anchors.map { |key, anchor| 
      [anchor[:name], key]
    }
  end

  def create
    @report = DatalabReport.new(report_params)
    @report.user = current_user

    if @report.save
      redirect_to datalab_designer_path(@report), notice: 'Report created successfully.'
    else
      @available_anchors = AnchorRegistry.available_anchors.map { |key, anchor| 
        [anchor[:name], key]
      }
      render :new
    end
  end

  def show
    @report = DatalabReport.find(params[:id])
    # Will implement report generation logic later
  end

  private def report_params
    params.require(:datalab_report).permit(:name, :description, :anchor_type, :is_public)
  end
end
