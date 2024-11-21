class Dwh::DpLogDecorator < BaseDecorator
  decorates :dp_log

  def status
    case dp_log.status
    when "success"
      "border-green-500"
    when "cancelled"
      "border-gray-300"
    when "alert"
      "border-red-500"
    end
  end
end
