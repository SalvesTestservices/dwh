module Dwh
  class FactTarget < DwhRecord
    validates :account_id, :original_id, :company_id, :year, :month, :role_group, presence: true
  end
end
