class View::FieldComponent < ViewComponent::Base
  def initialize(label:, attribute:, width: nil, position: "inline")
    @label = label
    @attribute = attribute
    @width = width
    @position = position
  end
end