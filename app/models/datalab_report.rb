class DatalabReport < ApplicationRecord
  belongs_to :user
  
  validates :name, presence: true
  validates :anchor_type, presence: true
  validates :column_config, presence: true
  
  # column_config JSON structure example:
  # {
  #   columns: [
  #     {
  #       id: "first_name",
  #       name: "First Name",
  #       sequence: 1,
  #       calculation_type: "direct" 
  #     },
  #     {
  #       id: "turnover",
  #       name: "Turnover",
  #       sequence: 2,
  #       calculation_type: "complex"
  #     }
  #   ]
  # }
end
