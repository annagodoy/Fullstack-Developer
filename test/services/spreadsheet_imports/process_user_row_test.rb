require "test_helper"

class SpreadsheetImports::ProcessUserRowTest < ActiveSupport::TestCase
  setup do
    @user_import = UserImport.new(status: :processing, total_rows: 2)

    @user_import.spreadsheet.attach(
      io: StringIO.new(
        "full_name,email\nImported User,imported@example.com\n" \
        "Another User,another@example.com\n"
      ),
      filename: "users.csv",
      content_type: "text/csv"
    )

    @user_import.save!

    @processor = SpreadsheetImports::ProcessUserRow.new(@user_import)
  end

  test "creates an user and advances progress" do
    assert_difference "User.count", 1 do
      @processor.call(row, position: 1)
    end

    user = User.find_by!(email: "imported@example.com")

    assert_equal "Imported User", user.full_name
    assert user.member?
    assert user.password_digest.present?

    assert_equal 1, @user_import.reload.processed_rows
    assert_equal 0, @user_import.failed_rows
    assert_empty @user_import.row_errors
  end

  test "records validation errors without create an user" do
    invalid_row = row(email: "invalid")

    assert_no_difference "User.count" do
      @processor.call(invalid_row, position: 1)
    end

    assert_equal 1, @user_import.reload.processed_rows
    assert_equal 1, @user_import.failed_rows

    error = @user_import.row_errors.sole
    assert_equal 2, error.row_number
    assert_includes error.message, "Email"
  end

  test "preserves an existing user when the email is duplicated" do
    existing = users(:one)

    assert_no_changes -> { existing.reload.attributes } do
      assert_no_difference "User.count" do
        @processor.call(row(email: existing.email), position: 1)
      end
    end

    assert_equal 1, @user_import.reload.processed_rows
    assert_equal 1, @user_import.failed_rows
    assert_equal 1, @user_import.row_errors.count
  end

  test "dont process the same position twice" do
    @processor.call(row, position: 1)

    assert_no_difference [ "User.count", "UserImportError.count" ] do
      @processor.call(row, position: 1)
    end

    assert_equal 1, @user_import.reload.processed_rows
    assert_equal 0, @user_import.failed_rows
  end

  test "continues processing after an invalid row" do
    @processor.call(row(email: "invalid"), position: 1)

    next_row = row.merge(row_number: 4)

    assert_difference "User.count", 1 do
      @processor.call(next_row, position: 2)
    end

    assert_equal 2, @user_import.reload.processed_rows
    assert_equal 1, @user_import.failed_rows
    assert_equal 1, @user_import.row_errors.count
  end

  test "rejects out of order processing" do
    assert_no_difference "User.count" do
      assert_raises(ArgumentError) do
        @processor.call(row, position: 2)
      end
    end

    assert_equal 0, @user_import.reload.processed_rows
  end

  test "rejects processing a pending import" do
    @user_import.update!(status: :pending)

    assert_no_difference "User.count" do
      assert_raises(ArgumentError) do
        @processor.call(row, position: 1)
      end
    end

    assert_equal 0, @user_import.reload.processed_rows
  end

  private

  def row(email: "imported@example.com")
    {
      row_number: 2,
      attributes: {
        "full_name" => "Imported User",
        "email" => email,
        "role" => "member"
      }
    }
  end
end
