class AddAdministrationToAccounts < ActiveRecord::Migration[7.0]
  def change
    add_column :dim_accounts, :administration_globe, :string
    add_column :dim_accounts, :administration_synergy, :string

    add_index :dim_accounts, :administration_globe
    add_index :dim_accounts, :administration_synergy
  end
end 
