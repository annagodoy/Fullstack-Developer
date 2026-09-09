class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email, with: ->(e) { e.strip.downcase }
  normalizes :full_name, with: ->(name) { name.strip }

  validates :email,
    presence: true,
    uniqueness: true,
    format: { with: URI::MailTo::EMAIL_REGEXP }

  validates :password,
    length: { minimum: 12 },
    allow_nil: true

  validates :full_name, presence: true

  enum :role, { member: 0, admin: 1 }, validate: true
end
