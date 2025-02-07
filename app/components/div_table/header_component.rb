class DivTable::HeaderComponent < ViewComponent::Base
  def initialize(title:, align:)
    @title = title
    @align = align
  end
end