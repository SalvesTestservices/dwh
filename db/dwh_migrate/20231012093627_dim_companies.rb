class DimCompanies < ActiveRecord::Migration[7.0]
  def change
    create_table :dim_companies do |t|
      t.integer :account_id
      t.string :original_id
      t.string  :name
      t.string  :name_short
      t.string  :company_group
      t.integer :backbone_id

      t.timestamps
    end
    add_index :dim_companies, [:account_id, :original_id], unique: true
    add_index :dim_companies, :account_id
    add_index :dim_companies, :original_id
    add_index :dim_companies, :company_group
    add_index :dim_companies, :backbone_id
  end
end