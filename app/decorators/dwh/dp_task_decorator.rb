class Dwh::DpTaskDecorator < BaseDecorator
  decorates :dp_task

  def depends_on
    if dp_task.depends_on.blank?
      "-"
    else
      items = "<div class='flex flex-col items-center'>"
      dp_task.depends_on.each do |item|
        items += "<span class='w-48 #{set_color("teal")} text-center rounded px-1 text-xs font-medium mr-1 mb-1'>#{item}</span>"
      end
      items += "</div>"
      items.html_safe
    end
  end
end
