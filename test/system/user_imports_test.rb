require "application_system_test_case"
require "tempfile"

class UserImportsTest < ApplicationSystemTestCase
  include ActiveJob::TestHelper

  setup do
    admin = users(:one)

    admin.update!(role: :admin)
    sign_in_through_browser(admin)
  end

  test "admin import users and sees the result without reloading" do
    within "nav[aria-label='Main navigation']" do
      click_link "Import users"
    end

    assert_current_path new_admin_user_import_path

    Tempfile.create([ "browser-users", ".csv" ]) do |file|
      file.write(
        "full_name,email,role\n" \
        "Imported Member,browser-import@example.com,member\n" \
        "Invalid Member,invalid,member\n"
      )

      file.flush

      within "main" do
        attach_file "Spreadsheet", file.path
        click_button "Upload spreadsheet"
      end

      assert_selector "#import-status", text: "Pending"

      import = UserImport.order(:id).last
      assert_current_path admin_user_import_path(import)

      assert_enqueued_with(job: UserImportJob, args: [ import.id ])

      perform_enqueued_jobs(only: UserImportJob)

      assert_selector "#import-status", text: "Completed", wait: 10
      assert_selector "progress#import-progress[value='100']"

      within "section[aria-labelledby='import-errors-heading']" do
        assert_selector "tbody tr", count: 1

        within "tbody tr" do
          assert_selector "td", text: "3", exact_text: true
          assert_text "Email"
        end
      end

      assert_no_selector "[data-controller~='import-progress']"

      assert import.reload.completed?
      assert_equal 2, import.processed_rows
      assert_equal 1, import.failed_rows
      assert User.find_by!(email: "browser-import@example.com").member?
    end
  end

  test "import progress updates even without a stream subscription" do
    visit new_admin_user_import_path

    Tempfile.create([ "fallback-users", ".csv" ]) do |file|
      file.write(
        "full_name,email\n" \
        "Fallback Member,fallback-member@example.com\n"
      )
      file.flush

      within "main" do
        attach_file "Spreadsheet", file.path
        click_button "Upload spreadsheet"
      end

      assert_selector "#import-status", text: "Pending"
      assert_selector "[data-controller~='import-progress']"

      import = UserImport.order(:id).last

      page.execute_script(<<~JS)
        document.querySelectorAll("turbo-cable-stream-source")
          .forEach((element) => element.remove())
      JS

      assert_no_selector "turbo-cable-stream-source", visible: :all

      perform_enqueued_jobs(only: UserImportJob)

      assert_selector "#import-status", text: "Completed", wait: 10
      assert_selector "progress#import-progress[value='100']"
      assert_no_selector "[data-controller~='import-progress']"

      assert import.reload.completed?
      assert_equal 1, import.processed_rows
      assert_equal 0, import.failed_rows
    end
  end
end
