class DimCustomers < ActiveRecord::Migration[7.0]
  def change
    create_table :dim_customers do |t|
      t.integer :account_id
      t.string :original_id
      t.string  :name
      t.string  :status
      t.integer :backbone_id

      t.timestamps
    end
    add_index :dim_customers, [:account_id, :original_id], unique: true
    add_index :dim_customers, :account_id
    add_index :dim_customers, :original_id
    add_index :dim_customers, :status
    add_index :dim_customers, :backbone_id
  end
end