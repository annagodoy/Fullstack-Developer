require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  test "require authentication" do
    get profile_path

    assert_redirected_to new_session_path
  end

  test "show current user profile" do
    user = users(:one)
    sign_in_as(user)

    get profile_path

    assert_response :success
    assert_select "#profile-email", text: user.email
    assert_select "#profile-full-name", text: user.full_name
  end

  test "ignores another user id in the request" do
    user = users(:one)
    sign_in_as(user)

    get profile_path, params: {
      id: users(:two).id
    }

    assert_response :success
    assert_select "#profile-email", text: user.email
    assert_select "#profile-email", text: users(:two).email, count: 0
  end

  test "visitors cant edit or update profiles" do
    get edit_profile_path
    assert_redirected_to new_session_path

    user = users(:one)

    assert_no_changes -> { user.reload.email } do
      patch profile_path, params: {
        user: {
          email: "new-email@example.com"
        }
      }
    end

    assert_redirected_to new_session_path
  end

  test "renders the edit form for current user" do
    user = users(:one)
    sign_in_as(user)

    get edit_profile_path

    assert_response :success
    assert_select "input[name='user[email]'][value=?]", user.email
  end

  test "updates only the current users permitted params" do
    user  = users(:one)
    user2 = users(:two)
    sign_in_as(user)

    assert_no_changes -> { user2.reload.attributes } do
      patch profile_path, params: {
        id: user2.id,
        user: {
          id: user2.id,
          full_name: "New Name",
          email: "new-email@example.com",
          role: "admin"
        }
      }
    end

    assert_redirected_to profile_path
    assert_equal "New Name", user.reload.full_name
    assert_equal "new-email@example.com", user.email
    assert user.member?
  end

  test "rejects invalid email without saving changes" do
    user = users(:one)
    sign_in_as(user)

    assert_no_changes -> { user.reload.email } do
      patch profile_path, params: {
        user: {
          email: "invalid"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "[role='alert']", /Email/
  end
end
