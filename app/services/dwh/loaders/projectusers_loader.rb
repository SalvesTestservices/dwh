class Dwh::Loaders::ProjectusersLoader
  def init
  end

  def load_data(account)
    dim_account = Dwh::DimAccount.find_by(original_id: account.original_id)

    projectusers = Dwh::EtlStorage.where(account_id: account.id, identifier: "projectusers", etl: "transform")
    unless projectusers.blank?
      projectusers.each do |projectuser|
        dim_user        = Dwh::DimUser.find_by(account_id: dim_account.id, original_id: projectuser.data['user_id'])
        dim_project     = Dwh::DimProject.find_by(account_id: dim_account.id, original_id: projectuser.data['project_id'])

        unless dim_user.blank? or dim_project.blank?
          Dwh::FactProjectuser.upsert({ account_id: dim_account.id, original_id: projectuser.data['original_id'], project_id: dim_project.id, 
            user_id: dim_user.id, start_date: projectuser.data['start_date'], end_date: projectuser.data['end_date'], expected_end_date: projectuser.data['expected_end_date'] },
            unique_by: [:account_id, :original_id])
        end
        projectuser.destroy
      end
    end
  end
end