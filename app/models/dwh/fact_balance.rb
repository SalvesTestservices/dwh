module Dwh
  class FactBalance < DwhRecord
    validates :account_id, :user_id, :year, :previous_balance, :start_rights, :start_balance, presence: true
  end
end