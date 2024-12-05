module Dwh
  class FactActivity < DwhRecord
    validates :account_id, :original_id, :user_id, :company_id, :activity_date, :hours, presence: true
  end
end