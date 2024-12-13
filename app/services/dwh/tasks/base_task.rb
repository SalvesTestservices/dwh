class Dwh::Tasks::BaseTask < ApplicationJob
  def wait_on_dependencies(account_name, run, task)
    all_dependencies_finished = true

    Dwh::DataPipelineLogger.new.create_log(run.id, "success", "[#{account_name}] Wachten op voorgaande taken gestart voor taak [#{task.task_key}]")

    unless task.depends_on.blank?
      # Check each task if it has finished
      task.depends_on.each do |task_key|
        loop do
          dependent_task = run.dp_tasks.find_by(task_key: task_key)
          if dependent_task.blank?
            break
          else
            result = run.dp_results.find_by(dp_task_id: dependent_task.id)
            result.reload
    
            if ["failed", "cancelled"].include?(result.status)
              all_dependencies_finished = false
              break
            elsif result.status == "finished"
              break
            end  
          end
          sleep(5)
        end
      end
    end

    Dwh::DataPipelineLogger.new.create_log(run.id, "success", "[#{account_name}] Wachten op voorgaande taken beeindigd voor taak [#{task.task_key}]")

    all_dependencies_finished
  end

  def convert_to_fractional(value)
    value.blank? ? nil : value / 100.0
  end

  def contract_field(contract)
    case contract
    when "fixed"
      "#{I18n.t('.users.contracts.fixed')}"
    when "ibo"
      "#{I18n.t('.users.contracts.fixed')}"
    when "midlance"
      "#{I18n.t('.users.contracts.midlance')}"
    when "temporary"
      "#{I18n.t('.users.contracts.temporary')}"
    end
  end

  def role_field(user)
    if user.employee?
      user.trainee == true ? "Trainee" : I18n.t(".users.roles.#{user.role}")
    else
      I18n.t(".users.roles.#{user.role}")
    end
  end

  def employee_type_field(user)
    is_service_counter = 0
    active_projectusers = user.active_projects(Date.current.year, Date.current.month)
    unless active_projectusers.blank?
      active_projectusers.each do |projectuser|
        if projectuser.project.service?
          is_service_counter += 1
        end
      end
    end

    is_service_counter > 5 ? "Testbot" : "Consultant"
  end

  def numeric_string?(str)
    begin
      Integer(str)
      true
    rescue ArgumentError
      false
    end
  end

  def perform_quality_check(check_type, run, task, actual, expected, description=nil)
    if actual != expected
      Dwh::DpQualityCheck.create(dp_run_id: run.id, dp_task_id: task.id, check_type: check_type, description: description, actual: actual, expected: expected, result: "failed")
    else
      Dwh::DpQualityCheck.create(dp_run_id: run.id, dp_task_id: task.id, check_type: check_type, description: description, actual: actual, expected: expected, result: "success")
    end
  end
end