module Dwh
  class FactProjectuser < DwhRecord
    validates :account_id, :original_id, :user_id, :project_id, :start_date, presence: true
  end
end