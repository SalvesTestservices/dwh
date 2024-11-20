class FactActivities < ActiveRecord::Migration[7.0]
  def change
    create_table :fact_activities do |t|
      t.integer :account_id
      t.integer :original_id
      t.integer :customer_id
      t.integer :unbillable_id
      t.integer :user_id
      t.integer :company_id
      t.integer :projectuser_id
      t.integer :project_id
      t.integer :year
      t.integer :month
      t.integer :day
      t.decimal :hours, precision: 10, scale: 2
      t.decimal :rate, precision: 10, scale: 2

      t.timestamps
    end
    add_index :fact_activities, :account_id
    add_index :fact_activities, :original_id
    add_index :fact_activities, :customer_id
    add_index :fact_activities, :unbillable_id
    add_index :fact_activities, :user_id
    add_index :fact_activities, :company_id
    add_index :fact_activities, :projectuser_id
    add_index :fact_activities, :project_id
    add_index :fact_activities, :year
    add_index :fact_activities, :month
    add_index :fact_activities, :day
  end
end
