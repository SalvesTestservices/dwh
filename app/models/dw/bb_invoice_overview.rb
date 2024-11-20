class Dw::BbInvoiceOverview < DwRecord
  acts_as_tenant(:account)

  validates :uid, presence: true
end