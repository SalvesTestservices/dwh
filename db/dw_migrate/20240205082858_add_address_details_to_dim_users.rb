class AddAddressDetailsToDimUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :dim_users, :address, :string
    add_column :dim_users, :zipcode, :string
    add_column :dim_users, :city, :string
  end
end
