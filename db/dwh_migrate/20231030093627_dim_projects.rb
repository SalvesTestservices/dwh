class DimProjects < ActiveRecord::Migration[7.0]
  def change
    create_table :dim_projects do |t|
      t.integer :account_id
      t.string :original_id
      t.string  :name
      t.string  :status
      t.integer :company_id
      t.string  :calculation_type
      t.integer :start_date
      t.integer :end_date
      t.integer :expected_end_date
      t.integer :customer_id

      t.timestamps
    end
    add_index :dim_projects, [:account_id, :original_id, :start_date, :end_date], unique: true, name: 'index_dim_projects_on_acc_id_orig_id_start_end'
    add_index :dim_projects, :account_id
    add_index :dim_projects, :original_id
    add_index :dim_projects, :company_id
    add_index :dim_projects, :calculation_type
    add_index :dim_projects, :status
    add_index :dim_projects, :start_date
    add_index :dim_projects, :expected_end_date
    add_index :dim_projects, :end_date
    add_index :dim_projects, :customer_id
  end
end
