class DatalabReport < ApplicationRecord
  belongs_to :user
  
  validates :name, presence: true
  validates :anchor_type, presence: true
  validates :column_config, presence: true
  validates :report_type, presence: true
  validates :report_type, inclusion: { in: %w[detail group matrix] }

  def available_group_by_options
    case anchor_type.to_sym
    when :hours
      [
        ['Medewerker', 'user_id'],
        ['Maand', 'month']
      ]
    when :projects
      [['Klant', 'customer_id']]
    when :users
      [
        ['Medewerker', 'user_id'],
        ['Unit', 'company_id']
      ]
    else
      []
    end
  end
end
