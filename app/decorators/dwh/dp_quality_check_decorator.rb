class Dwh::DpQualityCheckDecorator < BaseDecorator
  decorates :dp_quality_check

  def check_type
    case dp_quality_check.check_type
    when "row_count"
      I18n.t('.dp_quality_check.check_types.row_count')
    end
  end

  def result
    case dp_quality_check.result
    when "success"
      "<span class='px-6 py-1 bg-green-600 rounded'></span>".html_safe
    when "failed"
      "<span class='px-6 py-1 bg-red-600 rounded'></span>".html_safe
    end
  end
end
