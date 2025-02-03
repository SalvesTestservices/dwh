class Dwh::Tasks::EtlRwsDwhToBackboneTask < Dwh::Tasks::BaseExactTask
  queue_as :default

  def perform(task_account_id, task_account_name, run, result, task)
    # Wait for alle dependencies to finish
    all_dependencies_finished = wait_on_dependencies(task_account_name, run, task)
    if all_dependencies_finished == false
      Dwh::DataPipelineLogger.new.create_log(run.id, "cancelled", "[#{task_account_name}] Taak [#{task.task_key}] geannuleerd")
      result.update(finished_at: DateTime.now, status: "cancelled")
      return
    end

    begin
      account = Account.find(task_account_id)
      api_url, api_key, administration = get_api_keys("synergy")

      # Cancel the task if the API keys are not valid
      if api_url.blank? or api_key.blank? or administration.blank?
        Dwh::DataPipelineLogger.new.create_log(run.id, "alert", "[#{account.name}] Invalid API keys")
        result.update(finished_at: DateTime.now, status: "error")
        return  
      end

      # Create new users in Backbone which were created in Synergy in the last 24 hours
      create_new_bb_users

      # Create or update RWS activities in Backbone
      create_or_update_rws_activities

      # Update result
      result.update(finished_at: DateTime.now, status: "finished")
      Dwh::DataPipelineLogger.new.create_log(run.id, "success", "[#{task_account_name}] Finished task [#{task.task_key}] successfully")
    rescue => e
      # Update result to failed if an error occurs
      result.update(finished_at: DateTime.now, status: "failed", error: e.message)
      Dwh::DataPipelineLogger.new.create_log(run.id, "alert", "[#{task_account_name}] Finished task [#{task.task_key}] with error: #{e.message}")
    end
  end

  private def create_or_update_rws_activities
    # Get customer RWS from dim_customers
    dim_account = Dwh::DimAccount.find_by(name: "Salves")
    rws = Dwh::DimCustomer.find_by(account_id: dim_account.id, name: "Rijkswaterstaat")

    # Get all RWS activities created or updated in the last 24 hours from fact_activities
    yesterday = (Date.today - 1.day).strftime('%d%m%Y').to_i
    activities = Dwh::FactActivity.where(account_id: dim_account.id, customer_id: rws.id, activity_date: yesterday)
    unless activities.blank?
      activities.each do |activity|
        # Convert activity date
        dim_date = Dwh::DimDate.find(activity.activity_date)
        activity_date = Date.new(dim_date.year, dim_date.month, dim_date.day)

        # Get project name
        project_name = Dwh::DimProject.find(activity.project_id).name

        # Get BB user id
        dim_user = Dwh::DimUser.find(activity.user_id)
        user_id = dim_user.blank? ? nil : dim_user.original_id

        # Get BB projectuser id
        fact_projectuser = Dwh::FactProjectuser.find(activity.projectuser_id)
        projectuser_id = fact_projectuser.blank? ? nil : fact_projectuser.original_id

        # Create request body
        body = {
          activity_date: activity_date,
          user_id: user_id,
          projectuser_id: projectuser_id,
          project_name: project_name,
          hours: activity.hours,
          rate: activity.rate,
        }

        # Create or update the activity in Backbone
        begin
          url = URI::Parser.new.escape("#{ENV['BACKBONE_API_URL']}/api/v1/create_or_update_activity?email=#{ENV['BACKBONE_API_EMAIL']}&password=#{ENV['BACKBONE_API_PASSWORD']}")
          
          response = HTTParty.post(
            url,
            body: body.to_json,
            headers: { 
              'Content-Type' => 'application/json',
              'Accept' => 'application/json'
            },
            timeout: 30,
            debug_output: $stdout
          )

          # Create data governance log
          if response.code == 201
            Dwh::DgLog.create!(object_id: activity.id, object_type: "fact_activity", action: "created_or_updated_in_bb", status: "success", trigger: "etl_rws_dwh_to_backbone_task")
          else
            error_message = JSON.parse(response.body)["error"]
            Dwh::DgLog.create!(object_id: activity.id, object_type: "fact_activity", action: "created_or_updated_in_bb", status: "failed", trigger: "etl_rws_dwh_to_backbone_task", error_message: error_message)
          end
        rescue => e
          # Create data governance log
          Dwh::DgLog.create!(object_id: activity.id, object_type: "fact_activity", action: "created_or_updated_in_bb", status: "failed", trigger: "etl_rws_dwh_to_backbone_task", error_message: e.message)
        end
      end
    end
  end

  private def create_new_bb_users
    users = Dwh::DimUser.where(created_at: (DateTime.now - 1.day)..DateTime.now)
    unless users.blank?
      users.each do |user|
        # Split full name into first name and last name
        name_parts = user.full_name.split(' ', 2)
        first_name = name_parts[0]
        last_name = name_parts[1]

        # Convert contract
        case user.contract
        when "Vast contract"
          contract = "fixed"
        when "Tijdelijk contract"
          contract = "temporary"
        when "Midlancer"
          contract = "midlance"
        end

        # Convert start date
        dim_date = Dwh::DimDate.find(user.start_date)
        start_date = Date.new(dim_date.year, dim_date.month, dim_date.day)
        
        # Create request body
        body = {
          first_name: first_name,
          last_name: last_name,
          user_email: user.email,
          start_date: start_date,
          contract: contract,
          contract_hours: user.contract_hours
        }
        
        # Create user in Backbone
        begin
          url = URI::Parser.new.escape("#{ENV['BACKBONE_API_URL']}/api/v1/create_user?email=#{ENV['BACKBONE_API_EMAIL']}&password=#{ENV['BACKBONE_API_PASSWORD']}")
          
          response = HTTParty.post(
            url,
            body: body.to_json,
            headers: { 
              'Content-Type' => 'application/json',
              'Accept' => 'application/json'
            },
            timeout: 30,
            debug_output: $stdout
          )

          # Create data governance log
          if response.code == 201
            Dwh::DgLog.create!(object_id: user.id, object_type: "dim_user", action: "created_in_bb", status: "success", trigger: "etl_rws_dwh_to_backbone_task")
          else
            error_message = JSON.parse(response.body)["error"]
            Dwh::DgLog.create!(object_id: user.id, object_type: "dim_user", action: "created_in_bb", status: "failed", trigger: "etl_rws_dwh_to_backbone_task", error_message: error_message)
          end
        rescue => e
          # Create data governance log
          Dwh::DgLog.create!(object_id: user.id, object_type: "dim_user", action: "created_in_bb", status: "failed", trigger: "etl_rws_dwh_to_backbone_task", error_message: e.message)
        end
      end
    end
  end
end