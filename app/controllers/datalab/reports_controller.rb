module Datalab
  class ReportsController < ApplicationController
    include Pagy::Backend
    before_action :set_report, only: [:show, :generate, :export]
    before_action :set_anchor_service, only: [:show, :generate, :export]

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
      @report.column_config = { columns: [] }

      respond_to do |format|
        if @report.save
          format.html { redirect_to datalab_designer_path(@report), notice: 'Report created successfully.' }
          format.turbo_stream { redirect_to datalab_designer_path(@report), notice: 'Report created successfully.' }
        else
          @available_anchors = AnchorRegistry.available_anchors.map { |key, anchor| 
            [anchor[:name], key]
          }
          format.html { render :new, status: :unprocessable_entity }
          format.turbo_stream { render :new, status: :unprocessable_entity }
        end
      end
    end

    def show
      records, data = ReportGenerator.new(@report, filter_params).generate
      @pagy, paginated_records = pagy(records, items: 25)
      @report_data = data.merge(
        rows: data[:rows].select { |row| paginated_records.include?(row[:id]) }
      )
      
      respond_to do |format|
        format.html
        format.turbo_stream if params[:page]
      end
    end

    def generate
      records, data = ReportGenerator.new(@report, filter_params).generate
      @pagy, paginated_records = pagy(records, items: 25)
      @report_data = data.merge(
        rows: data[:rows].select { |row| paginated_records.include?(row[:id]) }
      )
      
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

    private

    def set_report
      @report = DatalabReport.find(params[:id])
    end

    def set_anchor_service
      anchor = Datalab::AnchorRegistry.get_anchor(@report.anchor_type)
      @anchor_service = anchor[:service]
    end

    def filter_params
      {
        filters: params[:filters],
        sort_by: params[:sort_by],
        sort_direction: params[:sort_direction],
        page: params[:page]
      }
    end
  end
end
