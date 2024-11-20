class Table::LinkComponent < ViewComponent::Base
  def initialize(value:, path:, align:, mobile:)
    @value = value
    @path = path
    @align = align

    @mobile = mobile == "show" ? "" : "hidden sm:table-cell"
  end
end