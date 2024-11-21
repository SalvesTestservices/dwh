class FactActivities < ActiveRecord::Migration[7.0]
  def change
    create_table :fact_activities do |t|
      t.integer :account_id
      t.string :original_id
      t.integer :customer_id
      t.integer :unbillable_id
      t.integer :user_id
      t.integer :company_id
      t.integer :projectuser_id
      t.integer :project_id
      t.integer :activity_date
      t.decimal :hours, precision: 10, scale: 2
      t.decimal :rate, precision: 10, scale: 2
      t.integer :refreshed

      t.timestamps
    end
    add_index :fact_activities, [:account_id, :original_id], unique: true
    add_index :fact_activities, :account_id
    add_index :fact_activities, :original_id
    add_index :fact_activities, :customer_id
    add_index :fact_activities, :unbillable_id
    add_index :fact_activities, :user_id
    add_index :fact_activities, :company_id
    add_index :fact_activities, :projectuser_id
    add_index :fact_activities, :project_id
    add_index :fact_activities, :activity_date
    add_index :fact_activities, :refreshed
  end
end
