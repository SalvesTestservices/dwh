class Dwh::DpTasksController < ApplicationController
  before_action :authenticate_user!

  def new
    @dp_task = Dwh::DpTask.new
    @dp_pipeline = Dwh::DpPipeline.find(params[:dp_pipeline_id])
    @dp_tasks = @dp_pipeline.dp_tasks.order(:sequence)

    @breadcrumbs = []
    @breadcrumbs << [I18n.t('.dp_pipeline.titles.index'), dw_dp_pipelines_path]
    @breadcrumbs << [I18n.t('.dp_pipeline.titles.show'), dw_dp_pipeline_path(@dp_pipeline)]
    @breadcrumbs << [I18n.t('.dp_task.titles.new')]
  end

  def create
    @dp_task = Dwh::DpTask.new(dp_task_params)
    if @dp_task.save!
      redirect_to dw_dp_pipeline_path(@dp_task.dp_pipeline_id), notice: I18n.t('.dp_task.messages.created')
    else
      render action: "new", status: 422
    end
  end

  def edit
    @dp_task = Dwh::DpTask.find(params[:id])
    @dp_tasks = @dp_task.dp_pipeline.dp_tasks.order(:sequence)
  end

  def update
    @dp_task = Dwh::DpTask.find(params[:id])
    @dp_task.update(dp_task_params)
  end

  def destroy
    @dp_task = Dwh::DpTask.find(params[:id])
    @dp_task.destroy
  end

  def pause
    @dp_task = Dwh::DpTask.find(params[:dp_task_id])
    @dp_task.update(status: "inactive")
  end

  def start
    @dp_task = Dwh::DpTask.find(params[:dp_task_id])
    @dp_task.update(status: "active")
  end

  def move
    @dp_task = Dwh::DpTask.find(params[:id])
    @dp_task.insert_at(params[:position].to_i)
    head :ok
  end

  def dp_task_params
    params.require(:dw_dp_task).permit(:dp_pipeline_id, :name, :description, :task_key, :status, :sequence, depends_on: []).tap do |whitelisted|
      whitelisted[:depends_on] = params[:dw_dp_task][:depends_on].reject(&:empty?) if params[:dw_dp_task][:depends_on].is_a?(Array)
    end
  end
end
