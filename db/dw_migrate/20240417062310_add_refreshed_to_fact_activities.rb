class AddRefreshedToFactActivities < ActiveRecord::Migration[7.1]
  def change
    add_column :fact_activities, :refreshed, :integer
    add_index :fact_activities, :refreshed
  end
end
