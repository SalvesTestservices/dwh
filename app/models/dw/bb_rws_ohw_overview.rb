class Dw::BbRwsOhwOverview < DwRecord
  acts_as_tenant(:account)

  validates :uid, presence: true
end