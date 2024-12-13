class DivTable::HeaderComponent < ViewComponent::Base
  def initialize(title:, align:, mobile:)
    @title = title
    @align = align
    @mobile = mobile == "show" ? "" : "hidden md:table-cell"
  end
end