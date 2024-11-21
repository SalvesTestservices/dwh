module Dwh
  class DimCompany < DwhRecord
    acts_as_tenant(:account)

    validates :account_id, :name, presence: true
  end
end