class Form::SelectComponent < ViewComponent::Base
  def initialize(label:, form:, attribute:, collection:, value:, mandatory:, width: "w-full", position: "inline")
    @label = label
    @form = form
    @attribute = attribute
    @collection = collection
    @value = value
    @mandatory = mandatory
    @width = width
    @position = position
  end
end