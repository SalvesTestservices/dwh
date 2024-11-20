class AddShowUserToFactRates < ActiveRecord::Migration[7.1]
  def change
    add_column :fact_rates, :show_user, :string, default: "Y"
    add_index :fact_rates, :show_user
  end
end
