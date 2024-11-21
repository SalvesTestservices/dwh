class Dwh::DpResultDecorator < BaseDecorator
  decorates :dp_result

  def depends_on
    if dp_result.depends_on.blank?
      "-"
    else
      items = "<div class='flex flex-col items-center'>"
      dp_result.depends_on.each do |item|
        items += "<span class='w-48 #{set_color("teal")} text-center rounded px-1 text-xs font-medium mr-1 mb-1'>#{item}</span>"
      end
      items += "</div>"
      items.html_safe
    end
  end

  def status
    case dp_result.status
    when "started"
      "border-sky-500"
    when "finished"
      "border-green-500"
    when "failed"
      "border-red-500"
    end
  end
end
