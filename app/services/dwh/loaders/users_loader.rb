class Dwh::Loaders::UsersLoader
  def init
  end

  def load_data(account)
    dim_account = Dwh::DimAccount.find_by(original_id: account.original_id)
    users = Dwh::EtlStorage.where(account_id: account.id, identifier: "users", etl: "transform")
    unless users.blank?
      users.each do |user|
        dim_company = Dwh::DimCompany.find_by(account_id: dim_account.id, original_id: user.data['company_id'])
        unless dim_company.blank?
          # Find the user. If not found, create it, otherwise update it
          # If an existing user now has a different company, create a new user
          dim_user = Dwh::DimUser.find_by(account_id: dim_account.id, original_id: user.data['original_id'], company_id: dim_company.id)
          if dim_user.blank?
            dim_user = Dwh::DimUser.create({ account_id: dim_account.id, original_id: user.data['original_id'], full_name: user.data['full_name'], company_id: dim_company.id, 
              start_date: user.data['start_date'], leave_date: user.data['leave_date'], role: user.data['role'], email: user.data['email'], employee_type: user.data['employee_type'], 
              contract: user.data['contract'], contract_hours: user.data['contract_hours'], salary: user.data['salary'], address: user.data['address'],
              zipcode: user.data['zipcode'], city: user.data['city'], country: user.data['country']})
          else
            if dim_user.company_id != dim_company.id
              dim_user = Dwh::DimUser.create({ account_id: dim_account.id, original_id: user.data['original_id'], full_name: user.data['full_name'], company_id: dim_company.id, 
                start_date: user.data['start_date'], leave_date: user.data['leave_date'], role: user.data['role'], email: user.data['email'], employee_type: user.data['employee_type'], 
                contract: user.data['contract'], contract_hours: user.data['contract_hours'], salary: user.data['salary'], address: user.data['address'],
                zipcode: user.data['zipcode'], city: user.data['city'], country: user.data['country']})
            else
              dim_user.update({ account_id: dim_account.id, original_id: user.data['original_id'], full_name: user.data['full_name'], company_id: dim_company.id, 
                start_date: user.data['start_date'], leave_date: user.data['leave_date'], role: user.data['role'], email: user.data['email'], employee_type: user.data['employee_type'], 
                contract: user.data['contract'], contract_hours: user.data['contract_hours'], salary: user.data['salary'], address: user.data['address'],
                zipcode: user.data['zipcode'], city: user.data['city'], country: user.data['country']})
            end
          end

          # Also create user as account user, so it can login and view overviews
          if dim_user.role == "Medewerker"
            account_user = User.find_by(email: dim_user.email)
            if account_user.blank?
              User.create!(first_name: dim_user.full_name.split(" ")[0], last_name: dim_user.full_name.split(" ")[1], email: dim_user.email, role: "employee", label: dim_account.name)
            end
          end
        end
        user.destroy
      end
    end
  end
end