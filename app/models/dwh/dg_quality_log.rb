class Dwh::DgQualityLog < DwhRecord
  validates :result, presence: true
end