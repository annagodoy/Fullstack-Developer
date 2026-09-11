require "test_helper"

class UserImportJobTest < ActiveJob::TestCase
  test "import users from .CSV" do
    user_import = create_import(valid_csv)

    assert_difference "User.count", 2 do
      UserImportJob.perform_now(user_import.id)
    end

    assert user_import.reload.completed?
    assert_equal 2, user_import.total_rows
    assert_equal 2, user_import.processed_rows
    assert_equal 0, user_import.failed_rows
    assert_empty user_import.row_errors

    assert User.find_by!(email: "import-member@example.com").member?
    assert User.find_by!(email: "import-admin@example.com").admin?
  end

  test "import users from .XLSX" do
    user_import = create_import(
      File.binread(Rails.root.join("test/fixtures/files/users.xlsx")),
      filename: "users.xlsx",
      content_type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    )

    assert_difference "User.count", 2 do
      UserImportJob.perform_now(user_import.id)
    end

    assert user_import.reload.completed?
    assert_equal 2, user_import.processed_rows
    assert_equal 0, user_import.failed_rows
    assert User.exists?(email: "imported-user1@example.com")
    assert User.exists?(email: "imported-user2@example.com")
  end

  test "continues after an invalid row" do
    user_import = create_import(
      "full_name,email\n" \
      "Invalid User,invalid\n" \
      "Valid User,valid-import@example.com\n"
    )

    assert_difference "User.count", 1 do
      UserImportJob.perform_now(user_import.id)
    end

    assert user_import.reload.completed?
    assert_equal 2, user_import.processed_rows
    assert_equal 1, user_import.failed_rows

    error = user_import.row_errors.sole
    assert_equal 2, error.row_number
    assert_includes error.message, "Email"
    assert User.exists?(email: "valid-import@example.com")
  end

  test "fails when required headers are missing" do
    user_import = create_import("full_name\nUser\n")

    assert_no_difference "User.count" do
      UserImportJob.perform_now(user_import.id)
    end

    assert user_import.reload.failed?
    assert_equal "Missing columns: email.", user_import.error_message
    assert_equal 0, user_import.processed_rows
  end

  test "dont repeat a completed import" do
    user_import = create_import(valid_csv)

    UserImportJob.perform_now(user_import.id)

    assert_no_difference [ "User.count", "UserImportError.count" ] do
      UserImportJob.perform_now(user_import.id)
    end

    assert user_import.reload.completed?
    assert_equal 2, user_import.processed_rows
    assert_equal 0, user_import.failed_rows
  end

  test "resumes an import without repeating processed rows" do
    user_import = create_import(valid_csv)
    user_import.update!(status: :processing, total_rows: 2)

    SpreadsheetImports::ProcessUserRow.new(user_import).call(
      {
        row_number: 2,
        attributes: {
          "full_name" => "Imported Member",
          "email" => "import-member@example.com",
          "role" => "member"
        }
      },
      position: 1
    )

    user_import.update!(
      status: :failed,
      error_message: "The import could not be completed."
    )

    assert_difference "User.count", 1 do
      UserImportJob.perform_now(user_import.id)
    end

    assert user_import.reload.completed?
    assert_equal 2, user_import.processed_rows
    assert_equal 0, user_import.failed_rows
    assert_nil user_import.error_message
    assert_empty user_import.row_errors
  end

  private

  def create_import(content, filename: "users.csv", content_type: "text/csv")
    user_import = UserImport.new

    user_import.spreadsheet.attach(
      io: StringIO.new(content),
      filename: filename,
      content_type: content_type
    )

    user_import.save!

    user_import
  end

  def valid_csv
    "full_name,email,role\n" \
    "Imported Member,import-member@example.com,member\n" \
    "Imported Admin,import-admin@example.com,admin\n"
  end
end
