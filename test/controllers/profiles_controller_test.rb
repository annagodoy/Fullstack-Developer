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
end
