class DimUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :dim_users do |t|
      t.integer :account_id
      t.string :original_id
      t.string  :full_name
      t.integer :company_id
      t.integer :start_date
      t.integer :leave_date
      t.string  :role
      t.string  :email
      t.string  :employee_type
      t.string  :contract
      t.integer :contract_hours
      t.decimal :salary
      t.string  :address
      t.string  :zipcode
      t.string  :city
      t.string  :country
      t.integer :unavailable_before

      t.timestamps
    end
    add_index :dim_users, [:account_id, :original_id], unique: true
    add_index :dim_users, :account_id
    add_index :dim_users, :original_id
    add_index :dim_users, :company_id
    add_index :dim_users, :role
    add_index :dim_users, :employee_type
    add_index :dim_users, :contract
    add_index :dim_users, :start_date
    add_index :dim_users, :leave_date
    add_index :dim_users, :country
    add_index :dim_users, :unavailable_before
  end
end