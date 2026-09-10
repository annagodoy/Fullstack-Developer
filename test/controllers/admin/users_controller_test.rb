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

  test "members cannot create users" do
    sign_in_as(users(:one))

    get new_admin_user_path
    assert_response :forbidden

    assert_no_difference "User.count" do
      post admin_users_path, params: {
        user: {
          full_name: "Unauthorized User",
          email: "unauthorized@example.com",
          password: "test-password",
          role: "admin"
        }
      }
    end

    assert_response :forbidden
  end

  test "admins can create users without replacing their session" do
    admin = users(:one)
    admin.update!(role: :admin)
    sign_in_as(admin)

    get new_admin_user_path
    assert_response :success

    assert_difference "User.count", 1 do
      assert_no_difference "Session.count" do
        post admin_users_path, params: {
          user: {
            full_name: "New Member",
            email: "created@example.com",
            password: "test-password",
            role: "member"
          }
        }
      end
    end

    assert_redirected_to admin_users_path
    assert User.find_by!(email: "created@example.com").member?

    get profile_path
    assert_select "#profile-email", text: admin.email
  end

  test "invalid administrative creation renders errors" do
    admin = users(:one)
    admin.update!(role: :admin)
    sign_in_as(admin)

    assert_no_difference "User.count" do
      post admin_users_path, params: {
        user: {
          full_name: "New User",
          email: "invalid",
          password: "test-password",
          role: "member"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "[role='alert']", /Email/
  end
end
