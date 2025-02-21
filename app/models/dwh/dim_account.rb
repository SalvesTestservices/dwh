module Dwh
  class DimAccount < DwhRecord
    include PgSearch::Model
    multisearchable against: [:name]

    validates :original_id, :name, :is_holding, presence: true
  end
end