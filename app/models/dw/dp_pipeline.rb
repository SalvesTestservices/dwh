class Dw::DpPipeline < DwRecord
  acts_as_list
  
  has_many :dp_tasks, class_name: 'Dw::DpTask'
  has_many :dp_runs, class_name: 'Dw::DpRun'

  validates :name, :status, :frequency, presence: true

  def active?
    status == "active" ? true : false
  end
end