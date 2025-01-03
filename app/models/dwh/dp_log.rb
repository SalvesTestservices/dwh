class Dwh::DpLog < DwhRecord
  belongs_to :dp_run, class_name: 'Dwh::DpRun', foreign_key: :dp_run_id
  
  validates :dp_run_id, :message, :status, presence: true

  after_create_commit do
    Turbo::StreamsChannel.broadcast_append_to "logs_#{self.dp_run_id}", target: "logs_#{self.dp_run_id}", action: :append, partial: "dwh/dp_runs/dp_log", locals: { dp_log: self }
  end
end