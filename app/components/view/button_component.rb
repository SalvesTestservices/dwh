class View::ButtonComponent < ViewComponent::Base
  def initialize(title:, url:, button_type:, size:)
    @title = title
    @url = url
    @button_type = button_type

    case size
    when "small"
      @size = "px-1 sm:px-2.5 py-1.5 text-xs"
    when "medium"
      @size = "px-4 py-2 text-sm"
    when "large"
      @size = "sm:h-10 mt-1 px-1 sm:px-4 py-2 text-sm"
    end

    if @button_type == "delete_button" or @button_type == "delete_button_turbo"
      @color = "text-white bg-red-600 hover:bg-red-500"
    else
      @color = "text-gray-700 bg-gray-100 hover:bg-gray-50"
    end
  end
end

=begin
px-4 py-2 text-sm text-gray-700 bg-gray-100 hover:bg-gray-50 mr-1 border border-gray-300 shadow-sm font-medium rounded focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-gray-500

=end