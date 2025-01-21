class DatalabReportDecorator < BaseDecorator
  decorates :datalab_report

  def anchor_type(layout = "text")
    if layout == "text"
      I18n.t(".datalab.report.anchor_types.#{datalab_report.anchor_type}")
    else
      "<span class='#{set_color("blue")} #{set_label}'>#{I18n.t(".datalab.report.anchor_types.#{datalab_report.anchor_type}").downcase}</span>".html_safe
    end
  end

  def is_public
    if datalab_report.is_public
      "<span class='#{set_color("green")} #{set_label}'>#{I18n.t('.datalab.report.attributes.is_public')}</span>".html_safe
    end
  end

  def created
    I18n.t('.datalab.report.attributes.created_by') + ' ' + datalab_report.user.full_name + ' ' + I18n.t('.datalab.report.attributes.created_at') + ' ' + datalab_report.created_at.strftime("%d-%m-%Y")
  end
end
