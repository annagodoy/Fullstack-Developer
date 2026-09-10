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

  test "rejects a blank full name without saving changes" do
    user = users(:one)
    sign_in_as(user)

    assert_no_changes -> { user.reload.full_name } do
      patch profile_path, params: {
        user: {
          full_name: ""
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "[role='alert']", /Full name/
  end

  test "visitors cant delete profiles" do
    assert_no_difference -> { User.count } do
      delete profile_path
    end

    assert_redirected_to new_session_path
  end

  test "deletes the current user profile and the session" do
    user  = users(:one)
    user2 = users(:two)

    sign_in_as(user)

    user.sessions.create!

    assert_no_changes -> { user2.reload.attributes } do
      assert_difference "User.count", -1 do
        delete profile_path, params: {
          id: user2.id
        }
      end
    end

    assert_redirected_to new_session_path
    assert_not User.exists?(user.id)
    assert_not Session.exists?(user_id: user.id)
    assert_empty cookies[:session_id]

    get profile_path
    assert_redirected_to new_session_path
  end

  test "uploads an avatar to current user" do
    user = users(:one)
    sign_in_as(user)

    patch profile_path, params: {
      user: {
        avatar_image: fixture_file_upload("avatar.png", "image/png")
      }
    }

    assert_redirected_to profile_path
    assert user.reload.avatar_image.attached?
    assert_equal "image/png", user.avatar_image.content_type
  end

  test "visitor cant have avatars" do
    get avatar_profile_path

    assert_redirected_to new_session_path
  end

  test "returns not found when the current user has not an avatar " do
    sign_in_as(users(:one))

    get avatar_profile_path

    assert_response :not_found
  end

  test "shows the current user avatar" do
    user = users(:one)

    user.avatar_image.attach(
      fixture_file_upload("avatar.png", "image/png")
    )

    sign_in_as(user)

    get avatar_profile_path

    assert_response :success
    assert_equal "image/png", response.media_type
    assert_equal file_fixture("avatar.png").binread, response.body
    assert_includes response.headers["Cache-Control"], "no-store"
  end

  test "cannot select another user avatar" do
    user2 = users(:two)

    user2.avatar_image.attach(
      fixture_file_upload("avatar.png", "image/png")
    )

    sign_in_as(users(:one))

    get avatar_profile_path, params: {
      id: user2.id
    }

    assert_response :not_found
  end
end
