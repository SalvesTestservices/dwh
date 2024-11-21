class Dwh::DpTask < DwhRecord
  acts_as_list column: :sequence, scope: :dp_pipeline
  
  belongs_to :dp_pipeline, class_name: 'Dwh::DpPipeline', foreign_key: :dp_pipeline_id, counter_cache: true
  has_many :dp_results, class_name: 'Dwh::DpResult'
  has_many :dp_runs, class_name: 'Dwh::DpRun', through: :dp_results
  has_many :dp_quality_checks, class_name: 'Dwh::DpQualityCheck'

  validates :name, :task_key, :sequence, presence: true

  scope :active, -> { where(status: 'active') }
end