class Dwh::DpResult < DwhRecord
  belongs_to :dp_task, class_name: 'Dwh::DpTask', foreign_key: :dp_task_id
  belongs_to :dp_run, class_name: 'Dwh::DpRun', foreign_key: :dp_run_id

  after_save :update_run_status
  
  validates :dp_task_id, :dp_run_id, :started_at, :status, presence: true

  def update_run_status
    dp_run = Dwh::DpRun.find(self.dp_run_id)

    case self.status
    when "failed"
      dp_run.update(status: "failed")
    when "cancelled"
      dp_run.update(status: "cancelled")
    end

    Turbo::StreamsChannel.broadcast_replace_to "pipeline-result-#{self.id}", target: "pipeline-result-#{self.id}", action: :replace, partial: "dw/dp_pipelines/progress_item", locals: { task: self.dp_task, result: self }
  end
end