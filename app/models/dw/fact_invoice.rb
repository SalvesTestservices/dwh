module Dw
  class FactInvoice < DwRecord
    acts_as_tenant(:account)

    validates :account_id, :original_id, :status, :credit, :internal_charging, :quantity, :rate, :amount_excl_vat, :amount_incl_vat, presence: true
  end
end