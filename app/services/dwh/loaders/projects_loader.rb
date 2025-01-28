class Dwh::Loaders::ProjectsLoader
  def init
  end

  def load_data(account)
    dim_account = Dwh::DimAccount.find_by(original_id: account.id)

    projects = Dwh::EtlStorage.where(account_id: account.id, identifier: "projects", etl: "transform")
    unless projects.blank?
      projects.each do |project|
        dim_company   = Dwh::DimCompany.find_by(account_id: dim_account.id, original_id: project.data['company_id'])
        dim_customer  = Dwh::DimCustomer.find_by(account_id: dim_account.id, original_id: project.data['customer_id'])

        dim_company_id  = dim_company.blank? ? nil : dim_company.id
        dim_customer_id = dim_customer.blank? ? nil : dim_customer.id
        
        Dwh::DimProject.upsert(
          {
            account_id: dim_account.id, 
            original_id: project.data['original_id'], 
            name: project.data['name'], 
            status: project.data['status'],
            company_id: dim_company_id, 
            calculation_type: project.data['calculation_type'], 
            start_date: project.data['start_date'], 
            end_date: project.data['end_date'],
            expected_end_date: project.data['expected_end_date'],
            broker_id: project.data['broker_id'],
            customer_id: dim_customer_id
          }, 
          unique_by: [:account_id, :original_id]
        )
  
        project.destroy
      end
    end
  end
end