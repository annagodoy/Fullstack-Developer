admin_attributes = {
  full_name: ENV["ADMIN_FULL_NAME"],
  email: ENV["ADMIN_EMAIL"],
  password: ENV["ADMIN_PASSWORD"]
}

if admin_attributes.values.all?(&:blank?)
  puts "Admin seed skipped. Set ADMIN_FULL_NAME, ADMIN_EMAIL and ADMIN_PASSWORD."
else
  missing = admin_attributes.select { |_key, value| value.blank? }.keys

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
    User.create!(admin_attributes.merge(email: email, role: :admin))
    puts "Admin account created."
  end
end
