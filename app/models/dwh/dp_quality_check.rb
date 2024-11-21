class Dwh::DpQualityCheck < DwhRecord
  belongs_to :dp_run, class_name: 'Dwh::DpRun', foreign_key: :dp_run_id
  belongs_to :dp_task, class_name: 'Dwh::DpTask', foreign_key: :dp_task_id
  
  validates :dp_run_id, :dp_task_id, :check_type, :result, presence: true
end