module DataviewHelper
  def format_metric_value(key, value)
    case
    when value.is_a?(Numeric) && key.to_s.include?('rate')
      number_to_percentage(value, precision: 1)
    when value.is_a?(Numeric) && key.to_s.include?('revenue')
      number_to_currency(value, unit: '€', delimiter: '.', separator: ',')
    when value.is_a?(Numeric) && key.to_s.include?('hours')
      "#{number_with_precision(value, precision: 1)} hours"
    when value.is_a?(Numeric)
      number_with_delimiter(value)
    else
      value.to_s.titleize
    end
  end

  def trend_color_classes(trend)
    case trend
    when 'increasing'
      'bg-green-100 text-green-800'
    when 'decreasing'
      'bg-red-100 text-red-800'
    else
      'bg-yellow-100 text-yellow-800'
    end
  end
end
