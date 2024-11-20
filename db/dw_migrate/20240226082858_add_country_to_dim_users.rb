class AddCountryToDimUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :dim_users, :country, :string
    add_column :dim_users, :unavailable_before, :integer
    add_index :dim_users, :country
    add_index :dim_users, :unavailable_before
  end
end
