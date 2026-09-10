require "test_helper"

class Admin::UsersControllerTest < ActionDispatch::IntegrationTest
  test "redirects visitors to sign in" do
    get admin_users_path

    assert_redirected_to new_session_path
  end

  test "denies access to members" do
    sign_in_as(users(:one))

    get admin_users_path

    assert_response :forbidden
  end

  test "allows admins to see users" do
    admin = users(:one)
    admin.update!(role: :admin)
    sign_in_as(admin)

    get admin_users_path

    assert_response :success

    [ admin, users(:two) ].each do |user|
      assert_select "#user_#{user.id}" do
        assert_select "td", text: user.full_name
        assert_select "td", text: user.email
        assert_select "td", text: user.role.humanize
      end
    end
  end
end
