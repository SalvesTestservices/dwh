class DatalabReport < ApplicationRecord
  belongs_to :user
  
  validates :name, presence: true
  validates :anchor_type, presence: true
  validates :column_config, presence: true
  validates :report_type, presence: true
  validates :report_type, inclusion: { in: %w[detail group matrix] }
end
