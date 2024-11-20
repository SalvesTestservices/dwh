class ChangeOriginalIds < ActiveRecord::Migration[7.1]
  def up
    change_column :dim_companies, :original_id, :string
    change_column :dim_customers, :original_id, :string
    change_column :dim_projects, :original_id, :string
    change_column :dim_projectusers, :original_id, :string
    change_column :dim_unbillables, :original_id, :string
    change_column :dim_users, :original_id, :string
    change_column :fact_activities, :original_id, :string
    change_column :fact_contracts, :original_id, :string
    change_column :fact_invoices, :original_id, :string
    change_column :fact_targets, :original_id, :string
  end

  def down
    change_column :dim_companies, :original_id, 'integer USING CAST(original_id AS integer)'
    change_column :dim_customers, :original_id, 'integer USING CAST(original_id AS integer)'
    change_column :dim_projects, :original_id, 'integer USING CAST(original_id AS integer)'
    change_column :dim_projectusers, :original_id, 'integer USING CAST(original_id AS integer)'
    change_column :dim_unbillables, :original_id, 'integer USING CAST(original_id AS integer)'
    change_column :dim_users, :original_id, 'integer USING CAST(original_id AS integer)'
    change_column :fact_activities, :original_id, 'integer USING CAST(original_id AS integer)'
    change_column :fact_contracts, :original_id, 'integer USING CAST(original_id AS integer)'
    change_column :fact_invoices, :original_id, 'integer USING CAST(original_id AS integer)'
    change_column :fact_targets, :original_id, 'integer USING CAST(original_id AS integer)'
  end
end
