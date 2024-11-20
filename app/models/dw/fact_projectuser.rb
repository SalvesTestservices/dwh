module Dw
  class FactProjectuser < DwRecord
    acts_as_tenant(:account)

    validates :account_id, :original_id, :user_id, :project_id, :start_date, presence: true
  end
end