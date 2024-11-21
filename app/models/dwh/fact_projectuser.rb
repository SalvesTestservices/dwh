module Dwh
  class FactProjectuser < DwhRecord
    acts_as_tenant(:account)

    validates :account_id, :original_id, :user_id, :project_id, :start_date, presence: true
  end
end