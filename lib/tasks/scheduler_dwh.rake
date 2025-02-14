namespace :dwh do
  task run_hourly_data_pipelines: :environment do
    dp_pipelines = Dw::DpPipeline.where(status: "active", run_frequency: "hourly")
    unless dp_pipelines.blank?
      dp_pipelines.each do |dp_pipeline|
        Dw::DataPipelineExecutor.perform_later(dp_pipeline)
      end
    end
  end

  task run_daily_data_pipelines: :environment do
    dp_pipelines = Dw::DpPipeline.where(status: "active", run_frequency: "daily")
    unless dp_pipelines.blank?
      dp_pipelines.each do |dp_pipeline|
        Dw::DataPipelineExecutor.perform_later(dp_pipeline)
      end
    end
  end

  task run_monthly_data_pipelines: :environment do
    dp_pipelines = Dw::DpPipeline.where(status: "active", run_frequency: "monthly")
    unless dp_pipelines.blank?
      dp_pipelines.each do |dp_pipeline|
        Dw::DataPipelineExecutor.perform_later(dp_pipeline)
      end
    end
  end

  task remove_unemployed_users: :environment do
    account_users = User.where(role: "employee")
    unless account_users.blank?
      account_users.each do |account_user|
        dim_user = Dwh::DimUser.find_by(email: account_user.email)
        if dim_user.blank?
          account_user.user_roles.destroy_all
          account_user.destroy
        else
          unless dim_user.leave_date.blank?
            # Ensure 8 digits with leading zeros
            date_str = dim_user.leave_date.to_s.rjust(8, '0')            
            month = date_str[0,2].to_i
            day = date_str[2,2].to_i
            year = date_str[4,4].to_i
            leave_date = Date.new(year, month, day)
            
            if leave_date < Date.current
              account_user.user_roles.destroy_all
              account_user.destroy
            end
          end
        end
      end
    end
  end

end
