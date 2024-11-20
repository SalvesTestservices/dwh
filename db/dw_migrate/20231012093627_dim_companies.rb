class DimCompanies < ActiveRecord::Migration[7.0]
  def change
    create_table :dim_companies do |t|
      t.integer :account_id
      t.integer :original_id
      t.string  :name
      t.string  :name_short

      t.timestamps
    end
    add_index :dim_companies, :account_id
    add_index :dim_companies, :original_id
  end
end
