module Dwh
  class DimUser < DwhRecord
    validates :original_id, :account_id, :company_id, presence: true
  end
end