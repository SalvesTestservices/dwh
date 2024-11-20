class Dw::BbGroupedWorkOverview < DwRecord
  acts_as_tenant(:account)

  validates :uid, presence: true
end