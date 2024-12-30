class Dwh::DpPipelinesController < ApplicationController
  before_action :authenticate_user!

  def index
    @dp_pipelines = Dwh::DpPipeline.includes(:dp_tasks).includes(:dp_runs).order(position: :asc)

    @breadcrumbs = []
    @breadcrumbs << [I18n.t('.dp_pipeline.titles.index')]
  end

  def show
    @dp_pipeline = Dwh::DpPipeline.find(params[:id])
    @dp_tasks = @dp_pipeline.dp_tasks.order(:sequence)
    @pagy, @dp_runs = pagy(@dp_pipeline.dp_runs.order(started_at: :desc), items: 10)
    @dp_task = Dwh::DpTask.new

    @breadcrumbs = []
    @breadcrumbs << [I18n.t('.dp_pipeline.titles.index'), dwh_dp_pipelines_path]
    @breadcrumbs << [I18n.t('.dp_pipeline.titles.show')]
  end

  def new
    @dp_pipeline = Dwh::DpPipeline.new
    get_form_data

    @breadcrumbs = []
    @breadcrumbs << [I18n.t('.dp_pipeline.titles.index'), dwh_dp_pipelines_path]
    @breadcrumbs << [I18n.t('.dp_pipeline.titles.new')]
  end

  def create
    @dp_pipeline = Dwh::DpPipeline.new(dp_pipeline_params)
    if @dp_pipeline.save
      redirect_to dwh_dp_pipelines_path, notice: I18n.t('.dp_pipeline.messages.created')
    else
      get_form_data
      render action: "new", status: 422
    end
  end

  def edit
    @dp_pipeline = Dwh::DpPipeline.find(params[:id])
    get_form_data

    @breadcrumbs = []
    @breadcrumbs << [I18n.t('.dp_pipeline.titles.index'), dwh_dp_pipelines_path]
    @breadcrumbs << [I18n.t('.dp_pipeline.titles.index'), dwh_dp_pipeline_path(@dp_pipeline)]
    @breadcrumbs << [I18n.t('.dp_pipeline.titles.edit')]
  end

  def update
    @dp_pipeline = Dwh::DpPipeline.find(params[:id])
    if @dp_pipeline.update(dp_pipeline_params)
      redirect_to dwh_dp_pipeline_path(@dp_pipeline), notice: I18n.t('.dp_pipeline.messages.updated')
    else
      get_form_data
      render action: "new", status: 422
    end
  end

  def destroy
    @dp_pipeline = Dwh::DpPipeline.find(params[:id])
    @dp_pipeline.dp_tasks.destroy_all
    @dp_pipeline.dp_runs.destroy_all
    @dp_pipeline.destroy

    redirect_to dwh_dp_pipelines_path, notice: I18n.t('.dp_pipeline.messages.destroyed')
  end

  def move
    @dp_pipeline = Dwh::DpPipeline.find(params[:id])
    @dp_pipeline.insert_at(params[:position].to_i)
    head :ok
  end

  private def get_form_data
    @accounts = Account.order(:name)
    @years = { "2025" => "2025", "2024" => "2024", "2023" => "2023","2022" => "2022", "2021" => "2021", "2020" => "2020" }
  end

  private def dp_pipeline_params
    params.require(:dwh_dp_pipeline).permit(:name, :status, :run_frequency, :load_method, :pipeline_key, :month, :year, :scoped_user_id, :account_id)
  end
end