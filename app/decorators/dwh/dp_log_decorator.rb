class Dwh::DpLogDecorator < BaseDecorator
  decorates :dp_log

  def status
    case dp_log.status
    when "success"
      "border-l-green-500"
    when "cancelled"
      "border-l-gray-300"
    when "alert"
      "border-l-red-500"
    end
  end
end
