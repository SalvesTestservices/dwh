class Dwh::DpRunDecorator < BaseDecorator
  decorates :dp_run

  def status
    return "border-l-sky-500" if dp_run.status == "started"
    return "border-l-gray-300" if dp_run.status == "cancelled"
  
    dp_quality_checks = dp_run.dp_quality_checks  
    if dp_quality_checks.blank?
      case dp_run.status
      when "finished"
        "border-l-green-500"
      when "failed"
        "border-l-red-500"
      end
    else
      if dp_quality_checks.where(result: "failed").exists?
        "border-l-red-500"
      else
        "border-l-green-500"
      end
    end
  end

  def duration
    if dp_run.started_at.blank? || dp_run.finished_at.blank?
      "-"
    else
      duration_in_seconds = dp_run.finished_at - dp_run.started_at
      if duration_in_seconds < 60
        "#{duration_in_seconds.to_i} seconden"
      elsif duration_in_seconds < 3600
        "#{(duration_in_seconds / 60).to_i} minuten"
      else
        hours = (duration_in_seconds / 3600).to_i
        minutes = ((duration_in_seconds % 3600) / 60).to_i
        "#{hours} uur, #{minutes} minuten"
      end
    end
  end
end