class AddCompanyGroupToDimCompanies < ActiveRecord::Migration[7.1]
  def change
    add_column :dim_companies, :company_group, :string
    add_index :dim_companies, :company_group
  end
end


