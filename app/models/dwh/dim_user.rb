module Dwh
  class DimUser < DwhRecord
    acts_as_tenant(:account)

    validates :original_id, :account_id, :company_id, presence: true
  end
end