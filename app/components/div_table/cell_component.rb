class DivTable::CellComponent < ViewComponent::Base
  def initialize(value:, align:)
    @value = value
    @align = align
  end
end