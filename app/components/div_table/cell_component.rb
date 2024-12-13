class DivTable::CellComponent < ViewComponent::Base
  def initialize(value:, align:, mobile:)
    @value = value
    @align = align
    @mobile = mobile == "show" ? "" : "hidden sm:table-cell"
  end
end