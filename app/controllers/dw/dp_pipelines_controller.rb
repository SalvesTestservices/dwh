class Dw::DpPipelinesController < ApplicationController
  before_action :authenticate_user!

  def index
    authorized_for?(:maintenance_view)

    @dp_pipelines = Dw::DpPipeline.includes(:dp_tasks).includes(:dp_runs).order(position: :asc)

    @breadcrumbs = []
    @breadcrumbs << [I18n.t('.dp_pipeline.titles.index')]
  end

  def show
    authorized_for?(:maintenance_view)

    @dp_pipeline = Dw::DpPipeline.find(params[:id])
    @accounts = Account.where(id: @dp_pipeline.account_ids).order(:name)
    @dp_tasks = @dp_pipeline.dp_tasks.order(:sequence)
    @pagy, @dp_runs = pagy(@dp_pipeline.dp_runs.order(started_at: :desc), items: 10)
    @dp_task = Dw::DpTask.new

    @breadcrumbs = []
    @breadcrumbs << [I18n.t('.dp_pipeline.titles.index'), dw_dp_pipelines_path]
    @breadcrumbs << [I18n.t('.dp_pipeline.titles.show')]
  end

  def new
    authorized_for?(:maintenance_view)

    @dp_pipeline = Dw::DpPipeline.new
    @accounts = Account.order(:name)

    @breadcrumbs = []
    @breadcrumbs << [I18n.t('.dp_pipeline.titles.index'), dw_dp_pipelines_path]
    @breadcrumbs << [I18n.t('.dp_pipeline.titles.new')]
  end

  def create
    authorized_for?(:maintenance_view)

    @dp_pipeline = Dw::DpPipeline.new(dp_pipeline_params)
    if @dp_pipeline.save
      redirect_to dw_dp_pipelines_path, notice: I18n.t('.dp_pipeline.messages.created')
    else
      @accounts = Account.order(:name)
      render action: "new", status: 422
    end
  end

  def edit
    authorized_for?(:maintenance_view)

    @dp_pipeline = Dw::DpPipeline.find(params[:id])
    @accounts = Account.order(:name)
    @years = Year.new.all_years

    @breadcrumbs = []
    @breadcrumbs << [I18n.t('.dp_pipeline.titles.index'), dw_dp_pipelines_path]
    @breadcrumbs << [I18n.t('.dp_pipeline.titles.index'), dw_dp_pipeline_path(@dp_pipeline)]
    @breadcrumbs << [I18n.t('.dp_pipeline.titles.edit')]
  end

  def update
    authorized_for?(:maintenance_view)

    @dp_pipeline = Dw::DpPipeline.find(params[:id])
    if @dp_pipeline.update(dp_pipeline_params)
      redirect_to dw_dp_pipeline_path(@dp_pipeline), notice: I18n.t('.dp_pipeline.messages.updated')
    else
      @accounts = Account.order(:name)
      @years = Year.new.all_years
      render action: "new", status: 422
    end
  end

  def destroy
    authorized_for?(:maintenance_view)

    @dp_pipeline = Dw::DpPipeline.find(params[:id])
    @dp_pipeline.dp_tasks.destroy_all
    @dp_pipeline.dp_runs.destroy_all
    @dp_pipeline.destroy

    redirect_to dw_dp_pipelines_path, notice: I18n.t('.dp_pipeline.messages.destroyed')
  end

  def move
    @dp_pipeline = Dw::DpPipeline.find(params[:id])
    @dp_pipeline.insert_at(params[:position].to_i)
    head :ok
  end

  private def dp_pipeline_params
    params.require(:dw_dp_pipeline).permit(:name, :description, :status, :frequency, :load_method, :pipeline_key, :month, :year, :scoped_user_id).tap do |whitelisted|
      whitelisted[:account_ids] = params[:dw_dp_pipeline][:account_ids].reject(&:empty?) if params[:dw_dp_pipeline][:account_ids].is_a?(Array)
    end
  end
end