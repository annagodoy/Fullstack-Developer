require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = User.take }

  test "new" do
    get new_session_path
    assert_response :success
  end

  test "create with valid credentials" do
    post session_path, params: { email: @user.email, password: "test-password" }

    assert_redirected_to root_path
  end

  test "create with invalid credentials" do
    post session_path, params: { email: @user.email, password: "wrong" }

    assert_redirected_to new_session_path
  end

  test "destroy" do
    sign_in_as(User.take)

    delete session_path

    assert_redirected_to new_session_path
  end

  test "redirect admins to dashboard after login" do
    @user.update!(role: :admin)

    get root_path
    assert_redirected_to new_session_path

    post session_path, params: {
      email: @user.email,
      password: "test-password"
    }

    assert_redirected_to admin_root_path
  end

  test "dont redirect members to the admin dashoboard" do
    get admin_root_path
    assert_redirected_to new_session_path

    post session_path, params: {
      email: @user.email,
      password: "test-password"
    }

    assert_redirected_to root_path

    get admin_root_path
    assert_response :forbidden
  end
end
