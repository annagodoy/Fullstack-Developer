require "test_helper"

class UserImportErrorTest < ActiveSupport::TestCase
  test "accepts an error for a row" do
    error = UserImportError.new(
      user_import: user_imports(:one),
      row_number: 3,
      message: "Email is invalid"
    )

    assert error.valid?, error.errors.full_messages.to_sentence
  end

  test "requires a message" do
    error = user_import_errors(:invalid_email)

    error.message = ""

    assert_not error.valid?
    assert error.errors.added?(:message, :blank)
  end

  test "rejects the header row" do
    error = user_import_errors(:invalid_email)

    error.row_number = 1

    assert_not error.valid?
    assert error.errors[:row_number].present?
  end

  test "rejects duplicate row errors within the same import" do
    existing = user_import_errors(:invalid_email)

    error = UserImportError.new(
      user_import: existing.user_import,
      row_number: existing.row_number,
      message: "Full name can't be blank"
    )

    assert_not error.valid?
    assert error.errors.added?(:row_number, :taken, value: existing.row_number)
  end

  test "allows the same row number in different imports" do
    error = UserImportError.new(
      user_import: user_imports(:two),
      row_number: user_import_errors(:invalid_email).row_number,
      message: "Email is invalid"
    )

    assert error.valid?, error.errors.full_messages.to_sentence
  end
end
