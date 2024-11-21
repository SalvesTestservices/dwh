class FactProjectusers < ActiveRecord::Migration[7.0]
  def change
    create_table :fact_projectusers do |t|
      t.integer :account_id
      t.string :original_id
      t.integer :user_id
      t.integer :project_id
      t.integer :start_date
      t.integer :end_date
      t.integer :expected_end_date

      t.timestamps
    end
    add_index :fact_projectusers, [:account_id, :original_id], unique: true
    add_index :fact_projectusers, :account_id
    add_index :fact_projectusers, :original_id
    add_index :fact_projectusers, :user_id
    add_index :fact_projectusers, :project_id
    add_index :fact_projectusers, :start_date
    add_index :fact_projectusers, :end_date
    add_index :fact_projectusers, :expected_end_date
  end
end
