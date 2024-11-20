class Dw::Loaders::RatesLoader
  def init
  end

  def load_data(account)
    dim_account = Dw::DimAccount.find_by(original_id: account.id)

    rates = Dw::EtlStorage.where(account_id: account.id, identifier: "rates", etl: "transform")
    unless rates.blank?
      rates.each do |rate|
        dim_company = Dw::DimCompany.find_by(account_id: dim_account.id, original_id: rate.data['company_id'])
        dim_user    = Dw::DimUser.find_by(account_id: dim_account.id, original_id: rate.data['user_id'])

        unless dim_user.blank?
          Dw::FactRate.upsert({ account_id: dim_account.id, user_id: dim_user.id, company_id: dim_company.id, rate_date: rate.data['rate_date'], avg_rate: rate.data['avg_rate'], 
            hours: rate.data['hours'], bcr: rate.data['bcr'], ucr: rate.data['ucr'], company_bcr: rate.data['company_bcr'], company_ucr: rate.data['company_ucr'], 
            contract: rate.data['contract'], contract_hours: rate.data['contract_hours'], salary: rate.data['salary'], role: rate.data['role'], show_user: rate.data['show_user'] }, 
            unique_by: [:account_id, :user_id, :rate_date])
        end
        rate.destroy
      end
    end
  end
end