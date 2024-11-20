module Dw
  class DimCustomer < DwRecord
    acts_as_tenant(:account)

    validates :name, :status, :original_id, :account_id, presence: true
  end
end