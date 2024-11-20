class AddAttributesToFactTargets < ActiveRecord::Migration[7.1]
  def change
    add_column :fact_targets, :workable_hours, :integer
    add_column :fact_targets, :productivity, :decimal, precision: 5, scale: 2
    add_column :fact_targets, :hour_rate, :decimal, precision: 5, scale: 2
    add_column :fact_targets, :turnover, :decimal, precision: 10, scale: 2
  end
end
