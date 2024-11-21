class BaseDecorator
  def initialize(object, template)
    @object = object
    @template = template
  end

  def self.decorates(name)
    define_method(name) do
      @object
    end
  end

  def method_missing(*args, &block)
    @template.send(*args, &block)
  end

  def end_date(end_date)
    if end_date.blank?
      "-"
    elsif end_date > Date.today + 60.days
      "<span class='#{set_color("green")} #{set_label}'>#{end_date.strftime("%d-%m-%Y")}</span>".html_safe
    elsif end_date > Date.today + 30.days
      "<span class='#{set_color("yellow")} #{set_label}'>#{end_date.strftime("%d-%m-%Y")}</span>".html_safe
    elsif end_date > Date.today
      "<span class='#{set_color("orange")} #{set_label}'>#{end_date.strftime("%d-%m-%Y")}</span>".html_safe
    else
      "<span class='#{set_color("red")} #{set_label}'>#{end_date.strftime("%d-%m-%Y")}</span>".html_safe
    end
  end

  def data_field(value, data_type="text", options={})
    case data_type
    when "text"
      data_field_text(value)
    when "date"
      data_field_date(value)
    when "time"
      data_field_time(value, options)
    when "decimal"
      data_field_decimal(value)
    when "percentage"
      data_field_percentage(value)
    when "amount"
      data_field_amount(value, options)
    when "boolean"
      data_field_boolean(value)
    end
  end

  def set_color(color)
    case color
    when "gray"
      "bg-gray-100 text-gray-700 border border-gray-700"
    when "green"
      "bg-green-100 text-green-700 border border-green-700"
    when "dark-green"
      "bg-green-600 text-white border border-green-600"
    when "red"
      "bg-red-100 text-red-700 border border-red-700"
    when "orange"
      "bg-orange-100 text-orange-700 border border-orange-700"
    when "lime"
      "bg-lime-300 text-lime-700 border border-lime-700"
    when "blue"
      "bg-sky-100 text-sky-700 border border-sky-700"
    when "purple"
      "bg-purple-100 text-purple-700 border border-purple-700"
    when "teal"
      "bg-teal-100 text-teal-700 border border-teal-700"
    when "yellow"
      "bg-yellow-100 text-yellow-700 border border-yellow-700"
    else
      "bg-gray-100 text-gray-700 border border-gray-700"
    end
  end

  def set_label
    "inline-flex items-center rounded px-2.5 py-0.5 mr-1 text-xs font-medium"
  end

  private def data_field_text(value)
    return "-" if value == false or value.blank?
    value
  end

  private def data_field_date(value)
    return "-" if value == false or value.blank?
    value.strftime("%d-%m-%Y")
  end

  private def data_field_time(value, options={})
    if value.blank?
      "-"
    elsif options[:seconds] == true
      value.strftime("%d-%m-%Y %H:%M:%S")
    else
      value.strftime("%d-%m-%Y %H:%M")
    end
  end

  private def data_field_decimal(value)
    value = value.to_f unless value.blank?

    if value.blank? or value == 0
      "-"
    else
      value.round(2)
    end
  end

  private def data_field_percentage(value)
    if value.blank?
      "-"
    elsif value.to_f == 0.0
      "-"
    else
      "#{value.to_f.round(1)}%"
    end
  end

  private def data_field_amount(value, options={})
    precision = options[:precision] || 2

    if value.blank?
      "-"
    else
      number_to_currency(value, 
        precision: precision, 
        separator: ',', 
        delimiter: '.', 
        unit: '€', 
        format: '%u %n')
    end
  end

  private def data_field_boolean(value)
    if value.blank? or value == false
      I18n.t(".general.titles.option_no")
    else
      I18n.t(".general.titles.option_yes")
    end
  end
end