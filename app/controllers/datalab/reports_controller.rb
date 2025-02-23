module Datalab
  class ReportsController < ApplicationController
    include Pagy::Backend
    before_action :authenticate_user!
    before_action :set_report, only: [:show, :edit, :update, :generate, :export, :destroy]
    before_action :set_anchor_service, only: [:show, :generate, :export]
    
    before_action -> { authorize!(:read, :datalab) }, only: [:index, :show, :generate, :export]
    before_action -> { authorize!(:write, :datalab) }, only: [:new, :create, :update]
    before_action -> { authorize!(:delete, :datalab) }, only: [:destroy]

    def index
      @reports = DatalabReport.where(user_id: current_user.id)
      @shared_reports = DatalabReport.where(is_public: true).where.not(user_id: current_user.id)

      @breadcrumbs = []
      @breadcrumbs << [I18n.t('.datalab.report.titles.index')]  
    end

    def new
      @report = DatalabReport.new
      @available_anchors = AnchorRegistry.available_anchors.map { |key, anchor| 
        [anchor[:name], key]
      }

    
      @breadcrumbs = []
      @breadcrumbs << [I18n.t('.datalab.report.titles.index'), datalab_reports_path]  
      @breadcrumbs << [I18n.t('.datalab.report.titles.new')]
    end

    def create
      @report = DatalabReport.new(report_params)
      @report.user = current_user
      @report.column_config = { columns: [] }

      respond_to do |format|
        if @report.save
          format.html { redirect_to datalab_designer_path(@report), notice: I18n.t('.datalab.report.messages.created') }
          format.turbo_stream { redirect_to datalab_designer_path(@report), notice: I18n.t('.datalab.report.messages.created') }
        else
          @available_anchors = AnchorRegistry.available_anchors.map { |key, anchor| 
            [anchor[:name], key]
          }
          format.html { render :new, status: :unprocessable_entity }
          format.turbo_stream { render :new, status: :unprocessable_entity }
        end
      end
    end

    def edit
      @available_anchors = AnchorRegistry.available_anchors.map { |key, anchor| 
        [anchor[:name], key]
      }

    
      @breadcrumbs = []
      @breadcrumbs << [I18n.t('.datalab.report.titles.index'), datalab_reports_path]
      @breadcrumbs << [@report.name, datalab_report_path(@report)]
      @breadcrumbs << [I18n.t('.datalab.report.titles.edit')]
    end

    def update
      if @report.update(report_params)
        respond_to do |format|
          format.html { redirect_to datalab_designer_path(@report), notice: I18n.t('.datalab.report.messages.updated') }
          format.turbo_stream { redirect_to datalab_designer_path(@report), notice: I18n.t('.datalab.report.messages.updated') }
        end
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def show
      @report = DatalabReport.find(params[:id])
      @report_generator = Datalab::ReportGenerator.new(
        @report,
        {
          filters: params[:filters],
          sort_by: params[:sort_by] || default_sort_field,
          sort_direction: params[:sort_direction] || 'asc',
          items_per_page: 50,
          page: params[:page] || 1
        }
      )

      @records, @report_data = @report_generator.generate
      
      @breadcrumbs = []
      @breadcrumbs << [I18n.t('.datalab.report.titles.index'), datalab_reports_path]  
      @breadcrumbs << [@report.name]

      respond_to do |format|
        format.html
        format.turbo_stream
      end
    end

    def generate
      report_params = {
        filters: params[:filters],
        sort_by: params[:sort_by] || default_sort_field,
        sort_direction: params[:sort_direction] || 'asc',
        items_per_page: 25,
        page: params[:page]
      }
      
      records, data = ReportGenerator.new(
        @report, 
        report_params
      ).generate
      
      @report_data = data

      @breadcrumbs = []
      @breadcrumbs << [I18n.t('.datalab.report.titles.index'), datalab_reports_path]  
      @breadcrumbs << [@report.name]

      respond_to do |format|
        format.html
      end
    end

    def export
      @report = DatalabReport.find(params[:id])
      
      records, data = ReportGenerator.new(
        @report, 
        filter_params.merge(items_per_page: nil) # No pagination for exports
      ).generate

      respond_to do |format|       
        format.csv do
          send_data generate_csv(records),
            filename: "#{@report.name.parameterize}-#{Date.today}.csv"
        end
      end
    end

    def destroy
      @report.destroy
      redirect_to datalab_reports_path, notice: I18n.t('.datalab.report.messages.destroyed')
    end

    private def report_params
      params.require(:datalab_report).permit(:name, :description, :anchor_type, :is_public)
    end

    private def set_report
      @report = DatalabReport.find(params[:id])
    end

    private def set_anchor_service
      anchor = Datalab::AnchorRegistry.get_anchor(@report.anchor_type)
      @anchor_service = anchor[:service]
    end

    private def default_sort_field
      anchor_service = Datalab::AnchorRegistry.get_anchor(@report.anchor_type)[:service]
      anchor_service.sortable_attributes.first&.to_s || 'id'
    end

    private def filter_params
      {
        filters: params[:filters],
        sort_by: params[:sort_by] || default_sort_field,
        sort_direction: params[:sort_direction] || 'asc',
        items_per_page: params[:items_per_page] || 50,
        page: params[:page] || 1
      }
    end
  end
end