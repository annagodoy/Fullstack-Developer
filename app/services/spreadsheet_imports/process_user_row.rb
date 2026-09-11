class SpreadsheetImports::ProcessUserRow
  def initialize(user_import)
    @user_import = user_import
  end

  def call(row, position:)
    @user_import.with_lock do
      next if position <= @user_import.processed_rows

      unless @user_import.processing?
        raise ArgumentError, "Import must be processing."
      end

      unless position == @user_import.processed_rows + 1
        raise ArgumentError, "Rows must be processed in order."
      end

      message = create_user(row.fetch(:attributes))

      if message
        @user_import.row_errors.create!(
          row_number: row.fetch(:row_number),
          message: message
        )

        @user_import.failed_rows += 1
      end

      @user_import.processed_rows += 1
      @user_import.save!
    end
  end

  private

  def create_user(attributes)
    User.transaction(requires_new: true) do
      User.create!(
        attributes.slice("full_name", "email", "role").merge(
          "password" => SecureRandom.hex(24)
        )
      )
    end

    nil
  rescue ActiveRecord::RecordNotUnique
    "Email has already been taken"
  rescue ActiveRecord::RecordInvalid => error
    error.record.errors.full_messages.to_sentence
  end
end
