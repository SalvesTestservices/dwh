class Form::TextFieldComponent < ViewComponent::Base
  def initialize(label:, form:, attribute:, mandatory:, autofocus:, width:, position: "inline")
    @label = label
    @form = form
    @attribute = attribute
    @mandatory = mandatory
    @autofocus = autofocus
    @width = width
    @position = position

    if  @position == "inline"
      case width
      when "small"
        @width = "w-1/3"
      when "medium"
        @width = "w-2/3"
      when "large"
        @width = "w-full"
      else
        @width = width
      end
    end
  end
end