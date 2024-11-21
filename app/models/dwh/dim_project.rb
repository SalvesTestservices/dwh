module Dwh
  class DimProject < DwhRecord
    acts_as_tenant(:account)

    validates :account_id, :original_id, :name, :status, :calculation_type, presence: true
  end
end