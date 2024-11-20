class Dw::Loaders::ActivitiesLoader
  def init
  end

  def load_data(account)
    dim_account = Dw::DimAccount.find_by(original_id: account.id)

    activities = Dw::EtlStorage.where(account_id: account.id, identifier: "activities", etl: "transform")
    unless activities.blank?
      activities.each do |activity|
        dim_user          = Dw::DimUser.find_by(account_id: dim_account.id, original_id: activity.data['user_id'])
        dim_company       = Dw::DimCompany.find_by(account_id: dim_account.id, original_id: activity.data['company_id'])
        dim_customer      = Dw::DimCustomer.find_by(account_id: dim_account.id, original_id: activity.data['customer_id'])
        fact_projectuser  = Dw::FactProjectuser.find_by(account_id: dim_account.id, original_id: activity.data['projectuser_id'])
        dim_project       = Dw::DimProject.find_by(account_id: dim_account.id, original_id: activity.data['project_id'])
        dim_unbillable    = Dw::DimUnbillable.find_by(account_id: dim_account.id, original_id: activity.data['unbillable_id'])

        dim_user_id         = dim_user.blank? ? nil : dim_user.id
        dim_company_id      = dim_company.blank? ? nil : dim_company.id
        dim_customer_id     = dim_customer.blank? ? nil : dim_customer.id
        dim_project_id      = dim_project.blank? ? nil : dim_project.id
        fact_projectuser_id = fact_projectuser.blank? ? nil : fact_projectuser.id
        dim_unbillable_id   = dim_unbillable.blank? ? nil : dim_unbillable.id
        dim_customer_id     = dim_customer.blank? ? nil : dim_customer.id

        Dw::FactActivity.upsert({ account_id: dim_account.id, original_id: activity.data['original_id'], customer_id: dim_customer_id, unbillable_id: dim_unbillable_id, 
          user_id: dim_user_id, company_id: dim_company_id, projectuser_id: fact_projectuser_id, project_id: dim_project_id, activity_date: activity.data['activity_date'], 
          hours: activity.data['hours'], rate: activity.data['rate'] }, unique_by: [:account_id, :original_id])

        activity.destroy
      end
    end
  end
end