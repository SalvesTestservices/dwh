class Dwh::DgQualityLog < DwhRecord
  validates :result, presence: true

  scope :unread, -> { where(read_at: nil) }
  scope :read, -> { where.not(read_at: nil) }
end
