class Dwh::DpPipeline < DwhRecord
  acts_as_list
  
  has_many :dp_tasks, class_name: 'Dwh::DpTask'
  has_many :dp_runs, class_name: 'Dwh::DpRun'

  validates :name, :pipeline_key, :status, :frequency, presence: true

  def active?
    status == "active" ? true : false
  end
end