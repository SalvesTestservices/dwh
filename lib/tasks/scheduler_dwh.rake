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

  task send_notifications: :environment do
    NotificationSender.new.send_notifications
  end

  task remove_unemployed_users: :environment do
    account_users = User.where(role: "employee")
    unless account_users.blank?
      account_users.each do |account_user|
        dim_users = Dwh::DimUser.where(email: account_user.email)
        if dim_users.blank?
          remove_user_and_roles(account_user)
        else
          if dim_users.count == 1
            dim_user = dim_users.first
            unless dim_user.leave_date.blank?
              leave_date = create_leave_date_from_integer(dim_user.leave_date)
              if leave_date < Date.current
                remove_user_and_roles(account_user)
              end
            end
          else
            if dim_users.all?(&:leave_date?)
              most_recent_leave_date = dim_users
                .map { |u| create_leave_date_from_integer(u.leave_date) }
                .max
              
              if most_recent_leave_date < Date.current
                remove_user_and_roles(account_user)
              end
            end
          end
        end
      end
    end
  end

  def remove_user_and_roles(account_user)
    account_user.user_roles.destroy_all
    account_user.destroy
  end

  def create_leave_date_from_integer(leave_date_integer)
    date_str = leave_date_integer.to_s.rjust(8, '0')            
    month = date_str[0,2].to_i
    day = date_str[2,2].to_i
    year = date_str[4,4].to_i
    Date.new(year, month, day)
  end
end
