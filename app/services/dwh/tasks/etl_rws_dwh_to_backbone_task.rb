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

      ### Users created for Salves in the last 24 hours ###

      account = Dwh::DimAccount.find_by(name: "Salves")
      users = Dwh::DimUser.where(account_id: account.id, created_at: (DateTime.now - 1.day)..DateTime.now)
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
            
            dump "Response: #{response.code} - #{response.body}"
          rescue => e
            dump "Error class: #{e.class}"
            dump "Error message: #{e.message}"
            dump "Error backtrace: #{e.backtrace.join("\n")}"
          end

        end
      end

=begin

      # Get customer RWS from dim_customers
      rws = Dwh::DimCustomer.find_by(account_id: account.id, name "Rijkswaterstaat")

      # Get all RWS activities created or updated in the last 24 hours from fact_activities
      dim_date = Dwh::DimDate.find_by(Date.today - 1.day)
      activities = Dwh::FactActivity.where(account_id: account.id, customer_id: rws.id, activity_date: dim_date.id)
      unless activities.blank?
        activities.each do |activity|
          # Check if activity exists in Backbone
          url = URI::Parser.new.escape("#{ENV['BACKBONE_API_URL']}/api/v1/get_activity?activity_id=#{activity.id}&email=#{ENV['BACKBONE_API_EMAIL']}&password=#{ENV['BACKBONE_API_PASSWORD']}")
          response = HTTParty.get(url)
          unless response.body.include?("error")
            # Parse the JSON response
      response_data = JSON.parse(response.body)


              activity_date  "dd-mm-yyy"
              hours
              rate
              unbillable_id = original_id!
              projectuser_id = original_id!
              project_name
              unbillable_name

# ook nieuwe medewerkers van salves ophalen en toevoegen

            # Alleen goedgekeurde activities toevoegen!!
        end
      end
=end
    

      # Update result
      result.update(finished_at: DateTime.now, status: "finished")
      Dwh::DataPipelineLogger.new.create_log(run.id, "success", "[#{task_account_name}] Finished task [#{task.task_key}] successfully")
    rescue => e
      # Update result to failed if an error occurs
      result.update(finished_at: DateTime.now, status: "failed", error: e.message)
      Dwh::DataPipelineLogger.new.create_log(run.id, "alert", "[#{task_account_name}] Finished task [#{task.task_key}] with error: #{e.message}")
    end
  end
end