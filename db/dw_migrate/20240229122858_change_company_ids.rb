class ChangeCompanyIds < ActiveRecord::Migration[7.1]
  def up
    change_column :dim_projects, :company_id, 'integer USING CAST(company_id AS integer)'
    change_column :dim_users, :company_id, 'integer USING CAST(company_id AS integer)'
    change_column :fact_activities, :company_id, 'integer USING CAST(company_id AS integer)'
    change_column :fact_contracts, :company_id, 'integer USING CAST(company_id AS integer)'
    change_column :fact_invoices, :company_id, 'integer USING CAST(company_id AS integer)'
    change_column :fact_rates, :company_id, 'integer USING CAST(company_id AS integer)'
    change_column :fact_targets, :company_id, 'integer USING CAST(company_id AS integer)'
  end

  def down
    change_column :dim_projects, :company_id, :string
    change_column :dim_users, :company_id, :string
    change_column :fact_activities, :company_id, :string
    change_column :fact_contracts, :company_id, :string
    change_column :fact_invoices, :company_id, :string
    change_column :fact_rates, :company_id, :string
    change_column :fact_targets, :company_id, :string
  end
end