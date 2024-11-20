module Dw
  class FactLedgerMutation < DwRecord
    acts_as_tenant(:account)

    validates :account_id, :original_reknr, :reknr, :origin, :administration, :year, :month, :mutation_date, :amount, :description, presence: true
  end
end