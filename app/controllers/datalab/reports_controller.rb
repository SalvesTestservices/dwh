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
    @report_data = ReportGenerator.new(@report, filter_params).generate
  end

  def generate
    @report = DatalabReport.find(params[:id])
    @report_data = ReportGenerator.new(@report, filter_params).generate
    
    respond_to do |format|
      format.html { render :show }
      format.json { render json: @report_data }
      format.turbo_stream
    end
  end

  private def report_params
    params.require(:datalab_report).permit(:name, :description, :anchor_type, :is_public)
  end

  private def filter_params
    {
      filters: params[:filters],
      sort_by: params[:sort_by],
      sort_direction: params[:sort_direction]
    }
  end
end
