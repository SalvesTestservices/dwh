class DimCustomers < ActiveRecord::Migration[7.0]
  def change
    create_table :dim_customers do |t|
      t.integer :account_id
      t.integer :original_id
      t.string  :name
      t.string  :status

      t.timestamps
    end
    add_index :dim_customers, :account_id
    add_index :dim_customers, :original_id
    add_index :dim_customers, :status
  end
end