class Dw::DpQualityCheck < DwRecord
  belongs_to :dp_run, class_name: 'Dw::DpRun', foreign_key: :dp_run_id
  belongs_to :dp_task, class_name: 'Dw::DpTask', foreign_key: :dp_task_id
  
  validates :dp_run_id, :dp_task_id, :check_type, :result, presence: true
end