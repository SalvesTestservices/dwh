class Dwh::DpRunsController < ApplicationController
  before_action :authenticate_user!

  def show
    @dp_run = Dwh::DpRun.includes(:dp_pipeline).find(params[:id])
    @dp_logs = @dp_run.dp_logs.order(:created_at)
    @dp_tasks = @dp_run.dp_pipeline.dp_tasks.order(:sequence)
    @dp_results = @dp_run.dp_results.order(:created_at)
    @dp_quality_checks = @dp_run.dp_quality_checks
    @account = Account.find(@dp_run.account_id)

    @breadcrumbs = []
    @breadcrumbs << [I18n.t('.dp_pipeline.titles.index'), dw_dp_pipelines_path]
    @breadcrumbs << [I18n.t('.dp_pipeline.titles.show'), dw_dp_pipeline_path(@dp_run.dp_pipeline_id)]
    @breadcrumbs << [I18n.t('.dp_run.titles.show')]
  end

  def create
    @dp_pipeline = Dwh::DpPipeline.find(params[:dp_pipeline_id])
    Dwh::DataPipelineExecutor.perform_later(@dp_pipeline)
  end

  def destroy
    @dp_run = Dwh::DpRun.find(params[:id])
    dp_pipeline_id = @dp_run.dp_pipeline_id
    @dp_run.dp_results.destroy
    @dp_run.dp_logs.destroy
    @dp_run.destroy

    redirect_to dw_dp_pipeline_path(dp_pipeline_id), notice: I18n.t('.dp_run.messages.destroyed')
  end

  def quality_checks
    @dp_run = Dwh::DpRun.find(params[:dp_run_id])
    @dp_tasks = @dp_run.dp_pipeline.dp_tasks.order(:sequence)
    @dp_results = @dp_run.dp_results.order(:created_at)
    @dp_quality_checks = @dp_run.dp_quality_checks
  
    @breadcrumbs = []
    @breadcrumbs << [I18n.t('.dp_pipeline.titles.index'), dw_dp_pipelines_path]
    @breadcrumbs << [I18n.t('.dp_pipeline.titles.show'), dw_dp_pipeline_path(@dp_run.dp_pipeline_id)]
    @breadcrumbs << [I18n.t('.dp_run.titles.show'), dw_dp_run_path(@dp_run.id)]
    @breadcrumbs << [I18n.t('.dp_quality_check.titles.index')]
  end
end