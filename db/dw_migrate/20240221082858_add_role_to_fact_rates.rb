class AddRoleToFactRates < ActiveRecord::Migration[7.1]
  def change
    add_column :fact_rates, :role, :string
    add_index :fact_rates, :role
  end
end
