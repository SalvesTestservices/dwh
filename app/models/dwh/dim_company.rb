module Dwh
  class DimCompany < DwhRecord
    include PgSearch::Model
    multisearchable against: [:name]

    validates :account_id, :name, presence: true
  end
end