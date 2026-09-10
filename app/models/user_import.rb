class UserImport < ApplicationRecord
  has_one_attached :spreadsheet

  enum :status, {
    pending: 0,
    processing: 1,
    completed: 2,
    failed: 3
  }, validate: true

  validates :total_rows, :processed_rows, :failed_rows,
    numericality: {
      only_integer: true,
      greater_than_or_equal_to: 0
    }

  validate :acceptable_spreadsheet

  private

  def acceptable_spreadsheet
    unless spreadsheet.attached?
      errors.add(:spreadsheet, "must be attached")
      return
    end

    unless spreadsheet.filename.extension.to_s.downcase.in?(%w[csv xlsx])
      errors.add(:spreadsheet, "must be a CSV or XLSX file")
    end

    if spreadsheet.byte_size > 5.megabytes
      errors.add(:spreadsheet, "must be 5MB or smaller")
    end
  end
end
