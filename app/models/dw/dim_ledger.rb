module Dw
  class DimLedger < DwRecord
    acts_as_tenant(:account)

    validates :account_id, :original_reknr, :reknr, :origin, :administration, :description, presence: true
  end
end