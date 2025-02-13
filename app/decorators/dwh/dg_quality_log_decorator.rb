class Dwh::DgQualityLogDecorator < BaseDecorator
  decorates :dg_quality_log

  def result
    if dg_quality_log.result == "failed"
      "<span class='#{set_color("red")} #{set_label}'>#{I18n.t('.dg_quality_log.results.failed')}</span>".html_safe
    else
      "<span class='#{set_color("green")} #{set_label}'>#{I18n.t('.dg_quality_log.results.success')}</span>".html_safe
    end
  end
end