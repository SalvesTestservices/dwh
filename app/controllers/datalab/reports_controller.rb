class Datalab::ReportsController < ApplicationController
  def index
    @reports = DatalabReport.where(user_id: current_user.id)
    @shared_reports = DatalabReport.where(is_public: true).where.not(user_id: current_user.id)
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
    
    respond_to do |format|
      format.html
      format.turbo_stream if params[:page]
    end
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

  def duplicate
    original_report = DatalabReport.find(params[:id])
    @report = DatalabReport.new(
      name: "#{original_report.name} (Copy)",
      description: original_report.description,
      anchor_type: original_report.anchor_type,
      column_config: original_report.column_config,
      user: current_user
    )

    if @report.save
      redirect_to datalab_designer_path(@report), notice: 'Report duplicated successfully.'
    else
      redirect_to datalab_reports_path, alert: 'Could not duplicate report.'
    end
  end

  def export
    @report = DatalabReport.find(params[:id])
    @report_data = ReportGenerator.new(@report, filter_params).generate

    respond_to do |format|
      format.csv do
        headers['Content-Disposition'] = "attachment; filename=\"#{@report.name.parameterize}-#{Date.current}.csv\""
        headers['Content-Type'] ||= 'text/csv'
      end
    end
  end

  private def report_params
    params.require(:datalab_report).permit(:name, :description, :anchor_type, :is_public)
  end

  private def filter_params
    {
      filters: params[:filters],
      sort_by: params[:sort_by],
      sort_direction: params[:sort_direction],
      page: params[:page]
    }
  end
end
