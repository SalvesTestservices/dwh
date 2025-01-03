module Dwh
  class FactRate < DwhRecord
    validates :account_id, :company_id, :user_id, :rate_date, :contract, :contract_hours, :salary, :show_user, presence: true
  end
end