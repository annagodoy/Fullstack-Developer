require "test_helper"

class UserImportTest < ActiveSupport::TestCase
  include ActionCable::TestHelper

  test "starts pending with zero counters" do
    user_import = UserImport.new

    assert user_import.pending?

    assert_equal 0, user_import.total_rows
    assert_equal 0, user_import.processed_rows
    assert_equal 0, user_import.failed_rows
  end

  test "rejects invalid status" do
    user_import = UserImport.new(status: :unknown)

    assert_not user_import.valid?
    assert user_import.errors.added?(:status, :inclusion, value: :unknown)
  end

  test "rejects negative counters" do
    %i[total_rows processed_rows failed_rows].each do |attribute|
      user_import = UserImport.new(attribute => -1)

      assert_not user_import.valid?
      assert user_import.errors[attribute].present?
    end
  end

  test "requires a spreadsheet" do
    user_import = UserImport.new

    assert_not user_import.valid?
    assert_includes user_import.errors[:spreadsheet], "must be attached"
  end

  test "accepts a CSV attachment" do
    user_import = UserImport.new

    user_import.spreadsheet.attach(
      io: StringIO.new("full_name,email\nUser,system-user@example.com\n"),
      filename: "users.csv",
      content_type: "text/csv"
    )

    assert user_import.valid?, user_import.errors.full_messages.to_sentence
  end

  test "rejects unsupported file extensions" do
    user_import = UserImport.new

    user_import.spreadsheet.attach(
      io: StringIO.new("plain text"),
      filename: "users.txt",
      content_type: "text/plain"
    )

    assert_not user_import.valid?
    assert_includes user_import.errors[:spreadsheet],
      "must be a CSV or XLSX file"
  end

  test "rejects spreadsheets larger than 5MB" do
    user_import = UserImport.new

    user_import.spreadsheet.attach(
      io: StringIO.new("x" * (5.megabytes + 1)),
      filename: "users.csv",
      content_type: "text/csv"
    )

    assert_not user_import.valid?
    assert_includes user_import.errors[:spreadsheet],
      "must be 5MB or smaller"
  end

  test "progress is zero before rows are counted" do
    assert_equal 0, UserImport.new.progress_porcentage
  end

  test "calculates progress of processed rows" do
    user_import = UserImport.new(total_rows: 4, processed_rows: 1)

    assert_equal 25, user_import.progress_porcentage
  end

  test "completed processing whn reaches 100% even with failed rows" do
    user_import = UserImport.new(
      total_rows: 4,
      processed_rows: 4,
      failed_rows: 1
    )

    assert_equal 100, user_import.progress_porcentage
  end

  test "refresh when progress changes" do
    user_import = UserImport.new(status: :processing, total_rows: 2)

    user_import.spreadsheet.attach(
      io: StringIO.new("full_name,email\nUser,user@example.com\n"),
      filename: "users.csv",
      content_type: "text/csv"
    )
    user_import.save!

    messages = capture_broadcasts(user_import.to_gid_param) do
      user_import.update!(processed_rows: 1)
    end

    assert_equal 1, messages.size

    stream = Nokogiri::HTML.fragment(messages.first).at_css("turbo-stream")
    assert_equal "refresh", stream&.[]("action")
  end
end
