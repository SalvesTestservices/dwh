class ReportMailer < ApplicationMailer
  def completion_notification(report)
    @report = report
    @user = report.user

    attachments[@report.filename] = @report.file.download
    
    mail(
      to: @user.email,
      subject: 'Your report is ready'
    )
  end
end
