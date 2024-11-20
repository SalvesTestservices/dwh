module Dw
  class FactTarget < DwRecord
    acts_as_tenant(:account)

    validates :account_id, :original_id, :company_id, :year, :month, :role_group, presence: true
  end
end
