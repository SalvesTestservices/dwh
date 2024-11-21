class Dwh::DpRun < DwhRecord
  belongs_to :dp_pipeline, class_name: 'Dwh::DpPipeline', foreign_key: :dp_pipeline_id, counter_cache: true
  has_many :dp_results, class_name: 'Dwh::DpResult', dependent: :destroy
  has_many :dp_tasks, class_name: 'Dwh::DpTask', through: :dp_results
  has_many :dp_logs, class_name: 'Dwh::DpLog', dependent: :destroy
  has_many :dp_quality_checks, class_name: 'Dwh::DpQualityCheck', dependent: :destroy
  
  validates :account_id, :dp_pipeline_id, :status, :started_at, presence: true

  after_create_commit do
    Turbo::StreamsChannel.broadcast_append_to "runs_#{self.dp_pipeline_id}", target: "runs_#{self.dp_pipeline_id}", action: :prepend, partial: "dw/dp_runs/dp_run", locals: { dp_run: self }
  end

  after_update_commit do
    Turbo::StreamsChannel.broadcast_replace_to "runs_#{self.dp_pipeline_id}", target: "dw_dp_run_#{self.id}", action: :replace, partial: "dw/dp_runs/dp_run", locals: { dp_run: self }
  end
end
 