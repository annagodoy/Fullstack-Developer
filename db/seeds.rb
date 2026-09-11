admin_attributes = {
  full_name: ENV["ADMIN_FULL_NAME"],
  email: ENV["ADMIN_EMAIL"]
}

admin_password = ENV["ADMIN_PASSWORD"]

if admin_attributes.values.all?(&:blank?) && admin_password.blank?
  puts "Admin seed skipped. Set ADMIN_FULL_NAME, ADMIN_EMAIL and ADMIN_PASSWORD."
else
  missing = admin_attributes.select { |_key, value| value.blank? }.keys

  missing << :password if admin_password.blank?

  if missing.any?
    raise ArgumentError,
      "Missing admin seed values: #{missing.join(', ')}."
  end

  email = admin_attributes.fetch(:email).strip.downcase
  existing_user = User.find_by(email: email)

  if existing_user
    unless existing_user.admin?
      raise ArgumentError,
        "The supplied email belongs to a member. No changes were made."
    end

    puts "Admin account already exists. No changes were made."
  else
    admin = User.new(
      full_name: admin_attributes.fetch(:full_name),
      email: email,
      role: :admin
    )

    admin.password = admin_password
    admin.save!

    puts "Admin account created."
  end
end
