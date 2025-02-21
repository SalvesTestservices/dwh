module Dwh
  class DimUser < DwhRecord
    include PgSearch::Model
    multisearchable against: [:full_name]

    validates :original_id, :account_id, :company_id, presence: true
  end
end