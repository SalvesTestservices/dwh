class AddSalaryToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :dim_users, :salary, :decimal
  end
end
