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

        assert_select "form[action=?]", admin_user_path(user) do
          assert_select "input[name='_method'][value='delete']"
          assert_select "button", text: "Delete"
        end
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

  test "members cant edit another user" do
    sign_in_as(users(:one))

    get edit_admin_user_path(users(:two))

    assert_response :forbidden
  end

  test "members cant update another user" do
    sign_in_as(users(:one))
    user = users(:two)

    assert_no_changes -> { user.reload.attributes } do
      patch admin_user_path(user), params: {
        user: { full_name: "Changed", role: "admin" }
      }
    end

    assert_response :forbidden
  end

  test "admins can edit users without changing passwords" do
    admin = users(:one)
    admin.update!(role: :admin)
    sign_in_as(admin)

    user = users(:two)

    get edit_admin_user_path(user)

    assert_response :success
    assert_select "input[type='password']", count: 0

    assert_no_changes -> { user.reload.password_digest } do
      patch admin_user_path(user), params: {
        user: {
          full_name: "Updated Name",
          email: "updated@example.com",
          role: "admin",
          password: "unwanted-password"
        }
      }
    end

    assert_redirected_to admin_users_path
    assert_equal "Updated Name", user.reload.full_name
    assert_equal "updated@example.com", user.email
    assert user.admin?
  end

  test "invalid edits preserve saved values" do
    admin = users(:one)
    admin.update!(role: :admin)
    sign_in_as(admin)

    user = users(:two)

    assert_no_changes -> { user.reload.attributes } do
      patch admin_user_path(user), params: { user: { email: "invalid" } }
    end

    assert_response :unprocessable_entity
    assert_select "[role='alert']", /Email/
  end

  test "admins who lose admin access" do
    admin = users(:one)
    admin.update!(role: :admin)

    sign_in_as(admin)

    patch admin_user_path(admin), params: {
      user: { role: "member" }
    }

    assert admin.reload.member?
    assert_redirected_to profile_path

    get admin_users_path
    assert_response :forbidden
  end

  test "returns not found when editing a missing user" do
    admin = users(:one)
    admin.update!(role: :admin)

    sign_in_as(admin)

    get edit_admin_user_path(-1)

    assert_response :not_found
  end

  test "allow admins to delete users" do
    admin = users(:one)
    admin.update!(role: :admin)

    user = users(:two)

    sign_in_as(admin)

    assert_no_changes -> { admin.reload.attributes } do
      assert_difference "User.count", -1 do
        delete admin_user_path(user)
      end
    end

    assert_redirected_to admin_users_path
    assert_not User.exists?(user.id)

    get admin_users_path
    assert_response :success
  end

  test "visitors cant delete users" do
    assert_no_difference "User.count" do
      delete admin_user_path(users(:two))
    end

    assert_redirected_to new_session_path
  end

  test "members cant delete users" do
    sign_in_as(users(:one))

    assert_no_difference "User.count" do
      delete admin_user_path(users(:two))
    end

    assert_response :forbidden
  end

  test "admins deleting their own account are signed out" do
    admin = users(:one)
    admin.update!(role: :admin)

    sign_in_as(admin)

    admin.sessions.create!

    assert_difference "User.count", -1 do
      delete admin_user_path(admin)
    end

    assert_redirected_to new_session_path
    assert_not User.exists?(admin.id)
    assert_not Session.exists?(user_id: admin.id)
    assert_empty cookies[:session_id]

    get admin_users_path
    assert_redirected_to new_session_path
  end

  test "paginates users without repeating records" do
    admin = users(:one)
    admin.update!(role: :admin)
    sign_in_as(admin)

    26.times do |number|
      User.create!(
        full_name: "New User #{number}",
        email: "new-user-#{number}@example.com",
        password: "test-password"
      )
    end

    get admin_users_path

    assert_response :success

    assert_equal users_ids.first(25).map { |id| "user_#{id}" }, page_ids
    assert_select "a[rel='next'][href=?]", admin_users_path(page: 2)
    assert_select "a[rel='prev']", count: 0

    get admin_users_path, params: { page: 2 }

    assert_response :success

    assert_equal users_ids.drop(25).map { |id| "user_#{id}" }, page_ids
    assert_select "a[rel='prev'][href=?]", admin_users_path(page: 1)
    assert_select "a[rel='next']", count: 0
  end

  test "invalid page values fall back to the first page" do
    admin = users(:one)
    admin.update!(role: :admin)

    sign_in_as(admin)

    [ "invalid", "0", "-1" ].each do |page|
      get admin_users_path, params: { page: page }

      assert_response :success
      assert_select "nav[aria-label='Users pagination'] span", text: "Page 1"
      assert_select "#user_#{admin.id}"
    end
  end

  private

  def users_ids
    User.order(:full_name, :id).pluck(:id)
  end

  def page_ids
    css_select("tbody tr").map { |row| row["id"] }
  end
end
