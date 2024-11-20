class ConvertDatesToDatekeys < ActiveRecord::Migration[7.1]
  def change
    remove_column :dim_projectusers, :start_date
    remove_column :dim_projectusers, :end_date
    add_column :dim_projectusers, :start_date, :integer
    add_column :dim_projectusers, :end_date, :integer
    remove_column :dim_users, :start_date
    remove_column :dim_users, :leave_date
    add_column :dim_users, :start_date, :integer
    add_column :dim_users, :leave_date, :integer
    remove_column :fact_activities, :day
    remove_column :fact_activities, :month
    remove_column :fact_activities, :year
    add_column :fact_activities, :activity_date, :integer
    remove_column :fact_ledger_mutations, :month
    remove_column :fact_ledger_mutations, :year
    add_column :fact_ledger_mutations, :mutation_date, :integer
    remove_column :fact_rates, :month
    remove_column :fact_rates, :year
    remove_column :fact_rates, :month_long
    add_column :fact_rates, :rate_date, :integer
  end
end
