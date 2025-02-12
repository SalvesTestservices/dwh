class DimCompanies < ActiveRecord::Migration[7.0]
  def change
    create_table :dim_companies do |t|
      t.integer :account_id
      t.string :original_id
      t.string  :name
      t.string  :name_short
      t.string  :company_group
      t.string  :old_original_id
      t.string  :old_source
      t.boolean :refreshed, default: false

      t.timestamps
    end
    add_index :dim_companies, [:account_id, :original_id], unique: true
    add_index :dim_companies, :account_id
    add_index :dim_companies, :original_id
    add_index :dim_companies, :company_group
    add_index :dim_companies, :old_original_id
    add_index :dim_companies, :old_source
    add_index :dim_companies, :refreshed
  end
end