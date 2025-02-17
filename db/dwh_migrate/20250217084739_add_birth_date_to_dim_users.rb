class AddBirthDateToDimUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :dim_users, :birth_date, :date
    add_index :dim_users, :birth_date
  end
end
