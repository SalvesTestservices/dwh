module Dwh
  class DimCustomer < DwhRecord
    acts_as_tenant(:account)

    validates :name, :status, :original_id, :account_id, presence: true
  end
end