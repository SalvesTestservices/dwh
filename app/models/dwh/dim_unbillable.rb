module Dwh
  class DimUnbillable < DwhRecord
    acts_as_tenant(:account)

    validates :account_id, :original_id, :name, :name_short, presence: true
  end
end