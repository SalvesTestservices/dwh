class DatalabReportDecorator < BaseDecorator
  decorates :datalab_report

  def anchor_type
    I18n.t(".datalab.report.anchor_types.#{datalab_report.anchor_type}")
  end
end
