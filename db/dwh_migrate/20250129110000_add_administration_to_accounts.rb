class AddAdministrationToAccounts < ActiveRecord::Migration[7.0]
  def change
    add_column :dim_accounts, :administration, :string
    add_index :dim_accounts, :administration
  end
end 
