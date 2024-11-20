class Form::CheckboxComponent < ViewComponent::Base
  def initialize(label:, form:, attribute:, mandatory:, width: "w-full", position: "inline")
    @label = label
    @form = form
    @attribute = attribute
    @mandatory = mandatory
    @width = width
    @position = position
  end
end