class Dwh::DpPipelineDecorator < BaseDecorator
  decorates :dp_pipeline

  def account
    case dp_pipeline.account
    when "cerios"
      "Cerios"
    when "salves"
      "Salves"
    when "valori"
      "Valori"
    when "qdata"
      "QDat"
    when "test_crew_it"
      "Test Crew IT"
    end
  end

  def load_method
    if dp_pipeline.load_method == "initial"
      I18n.t('.dp_pipeline.load_methods.initial')
    else
      I18n.t('.dp_pipeline.load_methods.incremental')
    end
  end

  def status
    case dp_pipeline.status
    when "inactive"
      "border-gray-500"
    when "active"
      "border-green-500"
    end
  end

  def progress(size)
    progress = ""

    height_width = size == "large" ? "w-10 h-10" : "w-6 h-6"

    dp_pipeline.dp_tasks.order(:sequence).each do |task|
      last_run = dp_pipeline.dp_runs.order(:created_at).last
      last_results = last_run.blank? ? nil : dp_pipeline.dp_runs.order(:created_at).last.dp_results  
      unless last_results.blank?
        result = last_results.find { |result| result.dp_task_id == task.id }
        task_status = result&.status

        case task_status
        when "started"
          color = "bg-sky-500 text-white"
        when "finished"
          color = "bg-green-600 text-white"
        when "failed"
          color = "bg-red-500 text-white"
        else
          color = "bg-gray-300 text-gray-800"
        end

        progress += "<div class='#{height_width} #{color} rounded-full flex text-xs font-bold items-center justify-center m-1'><span>#{task.sequence}</span></div>"
      end
    end
    progress.html_safe
  end

  def target(target)
    targets = ["own","from_others","to_others","subcos","services","internally_charged","projects","trainings","invoices","totals"]
    target_translations = [I18n.t('.users.overviews.own'), I18n.t('.users.overviews.from_others'), I18n.t('.users.overviews.to_others'), I18n.t('.users.overviews.subcos'), I18n.t('.users.overviews.services'), I18n.t('.users.overviews.internally_charged'), I18n.t('.users.overviews.fixed_projects'), I18n.t('.users.overviews.trainings'), I18n.t('.users.overviews.other_invoices'), I18n.t('.users.overviews.totals')]

    position = targets.index(target)
    target_translation = position.blank? ? "-" : target_translations[position]
    target_translation
  end

  def group(group)
    case group
    when "consultants_internal"
      I18n.t('.dp_pipeline.groups.consultants_internal')
    when "consultants_external"
      I18n.t('.dp_pipeline.groups.consultants_external')
    when "service"
      I18n.t('.dp_pipeline.groups.service')
    when "fixed_price"
      I18n.t('.dp_pipeline.groups.fixed_price')
    when "training"
      I18n.t('.dp_pipeline.groups.training')
    else
      I18n.t('.dp_pipeline.groups.total')
    end
  end
end