class AddEmailToDimBrokers < ActiveRecord::Migration[8.0]
  def change
    add_column :dim_brokers, :email, :string
    add_index :dim_brokers, :email
  end
end
