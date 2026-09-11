class UserImportError < ApplicationRecord
  belongs_to :user_import

  validates :row_number,
    numericality: {
      only_integer: true,
      greater_than_or_equal_to: 2
    },
    uniqueness: {
      scope: :user_import_id
    }

  validates :message, presence: true
end
