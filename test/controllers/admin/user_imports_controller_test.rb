require "test_helper"

class Admin::UserImportsControllerTest < ActionDispatch::IntegrationTest
  test "visitors cant access import pages and upload spreadsheets" do
    get new_admin_user_import_path
    assert_redirected_to new_session_path

    get admin_user_import_path(user_imports(:one))
    assert_redirected_to new_session_path

    assert_no_difference "UserImport.count" do
      post admin_user_imports_path, params: {
        user_import: { spreadsheet: spreadsheet }
      }
    end

    assert_redirected_to new_session_path
  end

  test "members cant access import pages and upload spreadsheets" do
    sign_in_as(users(:two))

    get new_admin_user_import_path
    assert_response :forbidden

    get admin_user_import_path(user_imports(:one))
    assert_response :forbidden

    sign_in_as(users(:two))

    assert_no_difference "UserImport.count" do
      post admin_user_imports_path, params: {
        user_import: { spreadsheet: spreadsheet }
      }
    end

    assert_response :forbidden
  end

  test "admins can access the upload page" do
    sign_in_as_admin

    get new_admin_user_import_path

    assert_response :success
    assert_select "input[type='file'][name='user_import[spreadsheet]']"
  end

  test "admins can upload and view a pending import" do
    sign_in_as_admin

    assert_difference "UserImport.count", 1 do
      post admin_user_imports_path, params: {
        user_import: { spreadsheet: spreadsheet }
      }
    end

    user_import = UserImport.order(:id).last

    assert user_import.pending?
    assert user_import.spreadsheet.attached?
    assert_redirected_to admin_user_import_path(user_import)

    follow_redirect!

    assert_response :success
    assert_select "#import-status", text: "Pending"
  end

  test "invalid uploads render validation errors" do
    sign_in_as_admin

    assert_no_difference "UserImport.count" do
      post admin_user_imports_path, params: {
        user_import: { spreadsheet: "" }
      }
    end

    assert_response :unprocessable_entity
    assert_select "[role='alert']", text: /must be attached/
  end

  test "upload cannot assign status or counters" do
    sign_in_as_admin

    post admin_user_imports_path, params: {
      user_import: {
        spreadsheet: spreadsheet,
        status: "completed",
        total_rows: 100,
        processed_rows: 100,
        failed_rows: 50
      }
    }

    assert_redirected_to admin_user_import_path(user_import)
    assert user_import.pending?
    assert_equal 0, user_import.total_rows
    assert_equal 0, user_import.processed_rows
    assert_equal 0, user_import.failed_rows
  end

  private

  def sign_in_as_admin
    admin = users(:one)
    admin.update!(role: :admin)
    sign_in_as(admin)
  end

  def spreadsheet
    fixture_file_upload("users.csv", "text/csv")
  end

  def user_import
    UserImport.order(:id).last
  end
end
