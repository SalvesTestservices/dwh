class DimCustomers < ActiveRecord::Migration[7.0]
  def change
    create_table :dim_customers do |t|
      t.integer :account_id
      t.string :original_id
      t.string  :name
      t.string  :status
      t.string  :old_original_id
      t.string  :old_source
      t.boolean :migrated, default: false

      t.timestamps
    end
    add_index :dim_customers, [:account_id, :original_id], unique: true
    add_index :dim_customers, :account_id
    add_index :dim_customers, :original_id
    add_index :dim_customers, :status
    add_index :dim_customers, :old_original_id
    add_index :dim_customers, :old_source
    add_index :dim_customers, :migrated
  end
end