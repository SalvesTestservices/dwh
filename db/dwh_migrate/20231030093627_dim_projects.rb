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
      t.integer :broker_id
      t.string  :old_original_id
      t.string  :old_source
      t.boolean :migrated, default: false

      t.timestamps
    end
    add_index :dim_projects, [:account_id, :original_id], unique: true, name: 'index_dim_projects_on_account_id_and_original_id'
    add_index :dim_projects, :account_id
    add_index :dim_projects, :original_id
    add_index :dim_projects, :company_id
    add_index :dim_projects, :calculation_type
    add_index :dim_projects, :status
    add_index :dim_projects, :start_date
    add_index :dim_projects, :expected_end_date
    add_index :dim_projects, :end_date
    add_index :dim_projects, :customer_id
    add_index :dim_projects, :broker_id
    add_index :dim_projects, :old_original_id
    add_index :dim_projects, :old_source
    add_index :dim_projects, :migrated
  end
end