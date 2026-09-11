require "test_helper"
require "tempfile"

class SpreadsheetImports::Readers::UsersTest < ActiveSupport::TestCase
  test "reads users and set default role to member" do
    rows = read_csv("full_name,email\nUser,system-user@example.com\n")

    assert_equal [ {
      row_number: 2,
      attributes: {
        "full_name" => "User",
        "email" => "system-user@example.com",
        "role" => "member"
      }
    } ], rows
  end

  test "normalizes headers and accepts a different column order" do
    rows = read_csv(
      " EMAIL , FULL_NAME , ROLE \nsystem-admin@example.com, Admin ,admin\n"
    )

    assert_equal "Admin", rows.first[:attributes]["full_name"]
    assert_equal "system-admin@example.com", rows.first[:attributes]["email"]
    assert_equal "admin", rows.first[:attributes]["role"]
  end

  test "ignores empty rows and preserves original row numbers" do
    rows = read_csv(
      "full_name,email\n,\nUser,system-user@example.com\n"
    )

    assert_equal 1, rows.size
    assert_equal 3, rows.first[:row_number]
  end

  test "rejects missing required columns" do
    error = assert_raises(
      SpreadsheetImports::Readers::Users::InvalidSpreadsheet
    ) do
      read_csv("full_name,role\nUser,member\n")
    end

    assert_equal "Missing columns: email.", error.message
  end

  test "rejects unknown columns" do
    assert_raises(SpreadsheetImports::Readers::Users::InvalidSpreadsheet) do
      read_csv("full_name,email,password\nUser,system-user@example.com,secret\n")
    end
  end

  test "rejects duplicate headers" do
    assert_raises(SpreadsheetImports::Readers::Users::InvalidSpreadsheet) do
      read_csv("full_name,email,email\nUser,system-user@example.com,system-user2@example.com\n")
    end
  end

  test "rejects blank headers" do
    assert_raises(SpreadsheetImports::Readers::Users::InvalidSpreadsheet) do
      read_csv("full_name,email,\nUser,system-user@example.com,value\n")
    end
  end

  test "rejects a file without data rows" do
    assert_raises(SpreadsheetImports::Readers::Users::InvalidSpreadsheet) do
      read_csv("full_name,email\n")
    end
  end

  test "rejects a file that exceeding row limit" do
    content = "full_name,email\n" +
      ("User,system-user@example.com\n" *
        (SpreadsheetImports::Readers::Users::MAX_ROWS + 1))

    assert_raises(SpreadsheetImports::Readers::Users::InvalidSpreadsheet) do
      read_csv(content)
    end
  end

  test "reads users from an XLSX spreadsheet" do
    rows = SpreadsheetImports::Readers::Users.new(
      Rails.root.join("test/fixtures/files/users.xlsx").to_s,
      extension: "xlsx"
    ).call

    assert_equal [
      {
        row_number: 2,
        attributes: {
          "full_name" => "Imported User",
          "email" => "imported-user1@example.com",
          "role" => "member"
        }
      },
      {
        row_number: 3,
        attributes: {
          "full_name" => "Imported User",
          "email" => "imported-user2@example.com",
          "role" => "member"
        }
      }
    ], rows
  end

  private

  def read_csv(content)
    Tempfile.create([ "users", ".csv" ]) do |file|
      file.write(content)
      file.flush

      SpreadsheetImports::Readers::Users.new(
        file.path,
        extension: "csv"
      ).call
    end
  end
end
