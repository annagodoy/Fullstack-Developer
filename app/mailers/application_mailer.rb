class ApplicationMailer < ActionMailer::Base
  default from: -> { ENV.fetch("MAIL_FROM", "System <system@example.com>") }

  layout "mailer"
end
