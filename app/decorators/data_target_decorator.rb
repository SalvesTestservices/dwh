class DataTargetDecorator < BaseDecorator
  decorates :data_target

  def sum(value)
    value == 0 ? 0 : value.round(0)
  end

  def avg(value, nr)
    value == 0 ? 0 : (value / nr).round(1)
  end
end
