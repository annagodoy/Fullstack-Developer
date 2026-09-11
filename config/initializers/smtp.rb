if Rails.env.production? && ENV["SMTP_ADDRESS"].present?
  Rails.application.config.action_mailer.delivery_method = :smtp
  Rails.application.config.action_mailer.perform_deliveries = true
  Rails.application.config.action_mailer.raise_delivery_errors = true

  Rails.application.config.action_mailer.smtp_settings = {
    address: ENV.fetch("SMTP_ADDRESS"),
    port: Integer(ENV.fetch("SMTP_PORT", "587")),
    user_name: ENV.fetch("SMTP_USERNAME"),
    password: ENV.fetch("SMTP_PASSWORD"),
    authentication: :plain,
    enable_starttls: true,
    open_timeout: 10,
    read_timeout: 10
  }

  ENV.fetch("MAIL_FROM")
  ENV.fetch("APP_HOST")
end
