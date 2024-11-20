module Dw
  class DimUser < DwRecord
    acts_as_tenant(:account)

    validates :original_id, :account_id, :company_id, presence: true
  end
end