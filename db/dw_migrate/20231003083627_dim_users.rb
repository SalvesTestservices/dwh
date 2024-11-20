class DimUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :dim_users do |t|
      t.integer :account_id
      t.integer :original_id
      t.string  :full_name
      t.integer :company_id
      t.date    :start_date
      t.date    :leave_date
      t.string  :role
      t.string  :email
      t.string  :employee_type
      t.string  :contract
      t.integer :contract_hours

      t.timestamps
    end
    add_index :dim_users, :account_id
    add_index :dim_users, :original_id
    add_index :dim_users, :company_id
    add_index :dim_users, :role
    add_index :dim_users, :employee_type
    add_index :dim_users, :contract
  end
end
