require "test_helper"

class Admin::DashboardControllerTest < ActionDispatch::IntegrationTest
  test "redirect visitors to login page" do
    get admin_root_path

    assert_redirected_to new_session_path
  end

  test "deny access to members" do
    user = users(:one)

    assert user.member?
    sign_in_as(user)

    get admin_root_path

    assert_response :forbidden
  end

  test "allow access to admins" do
    user = users(:one)

    user.update!(role: :admin)
    sign_in_as(user)

    get admin_root_path

    assert_response :success
    assert_select "h1", "Admin Dashboard"
  end

  test "shows user totals grouped by role" do
    admin = users(:one)
    admin.update!(role: :admin)
    sign_in_as(admin)

    get admin_root_path

    assert_response :success
    assert_select "#total-users", text: "2"
    assert_select "#admin-users", text: "1"
    assert_select "#member-users", text: "1"
  end
end
