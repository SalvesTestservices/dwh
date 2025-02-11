class Dwh::Loaders::CompaniesLoader
  def init
  end

  def load_data(account)
    dim_account = Dwh::DimAccount.find_by(original_id: account.id)

    companies = Dwh::EtlStorage.where(account_id: account.id, identifier: "companies", etl: "transform")
    unless companies.blank?
      companies.each do |company|
        Dwh::DimCompany.upsert({ account_id: dim_account.id, original_id: company.data['original_id'], name: company.data['name'], 
          name_short: company.data['name_short'], company_group: company.data['company_group'] }, unique_by: [:account_id, :original_id])

        company.destroy
      end
    end
  end
end