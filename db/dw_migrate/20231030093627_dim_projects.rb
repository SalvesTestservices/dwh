class DimProjects < ActiveRecord::Migration[7.0]
  def change
    create_table :dim_projects do |t|
      t.integer :account_id
      t.integer :original_id
      t.string  :name
      t.string  :status
      t.integer :company_id
      t.string  :calculation_type

      t.timestamps
    end
    add_index :dim_projects, :account_id
    add_index :dim_projects, :original_id
    add_index :dim_projects, :company_id
    add_index :dim_projects, :calculation_type
    add_index :dim_projects, :status
  end
end
