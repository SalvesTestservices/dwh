class Dwh::Loaders::UsersLoader
  def init
  end

  def load_data(account)
    dim_account = Dwh::DimAccount.find_by(original_id: account.id)
    users = Dwh::EtlStorage.where(account_id: account.id, identifier: "users", etl: "transform")
    unless users.blank?
      users.each do |user|
        dim_company = Dwh::DimCompany.find_by(account_id: dim_account.id, original_id: user.data['company_id'])
        unless dim_company.blank?
          # Find the user. If not found, create it, otherwise update it
          # If an existing user now has a different company, create a new user
          existing_user = Dw::DimUser.find_by(account_id: dim_account.id, original_id: user.data['original_id'])
          if existing_user.blank?
            Dw::DimUser.create({ account_id: dim_account.id, original_id: user.data['original_id'], full_name: user.data['full_name'], company_id: dim_company.id, 
              start_date: user.data['start_date'], leave_date: user.data['leave_date'], role: user.data['role'], email: user.data['email'], employee_type: user.data['employee_type'], 
              contract: user.data['contract'], contract_hours: user.data['contract_hours'], salary: user.data['salary'], address: user.data['address'],
              zipcode: user.data['zipcode'], city: user.data['city'], country: user.data['country']})
          else
            if existing_user.company_id != dim_company.id
              Dw::DimUser.create({ account_id: dim_account.id, original_id: user.data['original_id'], full_name: user.data['full_name'], company_id: dim_company.id, 
                start_date: user.data['start_date'], leave_date: user.data['leave_date'], role: user.data['role'], email: user.data['email'], employee_type: user.data['employee_type'], 
                contract: user.data['contract'], contract_hours: user.data['contract_hours'], salary: user.data['salary'], address: user.data['address'],
                zipcode: user.data['zipcode'], city: user.data['city'], country: user.data['country']})
            else
              existing_user.update({ account_id: dim_account.id, original_id: user.data['original_id'], full_name: user.data['full_name'], company_id: dim_company.id, 
                start_date: user.data['start_date'], leave_date: user.data['leave_date'], role: user.data['role'], email: user.data['email'], employee_type: user.data['employee_type'], 
                contract: user.data['contract'], contract_hours: user.data['contract_hours'], salary: user.data['salary'], address: user.data['address'],
                zipcode: user.data['zipcode'], city: user.data['city'], country: user.data['country']})
            end
          end
        end
        user.destroy
      end
    end
  end
end