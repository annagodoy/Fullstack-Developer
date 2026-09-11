class UserImportJob < ApplicationJob
  queue_as :default

  limits_concurrency to: 1,
    key: ->(user_import_id) { user_import_id },
    duration: 30.minutes

  def perform(user_import_id)
    user_import = UserImport.find_by(id: user_import_id)

    return unless user_import
    return if user_import.completed?

    rows = read_rows(user_import)

    user_import.update!(
      status: :processing,
      total_rows: rows.size,
      error_message: nil
    )

    processor = SpreadsheetImports::ProcessUserRow.new(user_import)

    rows.each_with_index do |row, index|
      processor.call(row, position: index + 1)
    end

    user_import.update!(status: :completed)
  rescue SpreadsheetImports::Readers::Users::InvalidSpreadsheet => error
    marks_failed(user_import, error.message)
  rescue StandardError
    marks_failed(user_import, "The import could not be completed.")
    raise
  end

  private

  def read_rows(user_import)
    user_import.spreadsheet.open do |file|
      SpreadsheetImports::Readers::Users.new(
        file.path,
        extension: user_import.spreadsheet.filename.extension
      ).call
    end
  end

  def marks_failed(user_import, message)
    return unless user_import&.persisted?

    user_import.with_lock do
      unless user_import.completed?
        user_import.update!(status: :failed, error_message: message)
      end
    end
  end
end
