class Dw::Loaders::ProjectsLoader
  def init
  end

  def load_data(account)
    dim_account = Dw::DimAccount.find_by(original_id: account.id)

    projects = Dw::EtlStorage.where(account_id: account.id, identifier: "projects", etl: "transform")
    unless projects.blank?
      projects.each do |project|
        dim_company   = Dw::DimCompany.find_by(account_id: dim_account.id, original_id: project.data['company_id'])
        dim_customer  = Dw::DimCustomer.find_by(account_id: dim_account.id, original_id: project.data['customer_id'])

        dim_company_id  = dim_company.blank? ? nil : dim_company.id
        dim_customer_id = dim_customer.blank? ? nil : dim_customer.id
        
        Dw::DimProject.upsert({ account_id: dim_account.id, original_id: project.data['original_id'], name: project.data['name'], status: project.data['status'], 
          company_id: dim_company_id, calculation_type: project.data['calculation_type'], start_date: project.data['start_date'], end_date: project.data['end_date'], 
          expected_end_date: project.data['expected_end_date'], customer_id: dim_customer_id }, unique_by: [:account_id, :original_id, :start_date, :end_date])

        project.destroy
      end
    end
  end
end