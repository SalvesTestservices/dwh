class View::LinkFieldComponent < ViewComponent::Base
  def initialize(label:, link_label:, path:, position: "inline")
    @label = label
    @link_label = link_label
    @path = path
    @position = position
  end
end
