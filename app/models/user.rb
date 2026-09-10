class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  has_one_attached :avatar_image

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

  validate :acceptable_avatar

  enum :role, { member: 0, admin: 1 }, validate: true

  private

  def acceptable_avatar
    return unless avatar_image.attached?

    unless avatar_image.content_type.in?(%w[image/jpeg image/png])
      errors.add(:avatar_image, "must be a JPEG or PNG")
    end

    if avatar_image.byte_size > 5.megabytes
      errors.add(:avatar_image, "must be 5MB or smaller")
    end
  end
end
