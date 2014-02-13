class AlertMailer < ActionMailer::Base
  include ActionView::Helpers::TextHelper
  default from: "contact@morph.io"

  def alert_email(user, broken_runs, successful_count)
    count = broken_runs.count
    @user, @broken_runs, @successful_count = user, broken_runs, successful_count
    @subject = "Morph: #{pluralize(count, 'scraper')} you are watching #{count == 1 ? "is" : "are"} erroring"
    mail(to: "#{user.name} <#{user.email}>", subject: @subject)
  end
end
