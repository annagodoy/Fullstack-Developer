require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "visitors can registrate" do
    get new_registration_path

    assert_response :success
    assert_select "form[action=?]", registration_path
  end

  test "creates a member and signs in despite a supplied admin role" do
    assert_difference "User.count", 1 do
      assert_difference "Session.count", 1 do
        post registration_path, params: {
          user: {
            full_name: "New Member",
            email: "new-member@example.com",
            password: "test-password",
            password_confirmation: "test-password",
            role: "admin"
          }
        }
      end
    end

    user = User.find_by!(email: "new-member@example.com")
    assert user.member?
    assert_redirected_to profile_path

    follow_redirect!
    assert_response :success
    assert_select "#profile-email", text: user.email
  end

  test "rejects invalid registration without creating a session" do
    assert_no_difference [ "User.count", "Session.count" ] do
      post registration_path, params: {
        user: {
          full_name: "",
          email: "invalid",
          password: "short",
          password_confirmation: "different"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "[role='alert']"
  end

  test "rejects an existing email after normalization" do
    assert_no_difference [ "User.count", "Session.count" ] do
      post registration_path, params: {
        user: {
          full_name: "Another User",
          email: " #{users(:one).email.upcase} ",
          password: "test-password",
          password_confirmation: "test-password"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "[role='alert']", /Email has already been taken/
  end

  test "requires password confirmation" do
    assert_no_difference [ "User.count", "Session.count" ] do
      post registration_path, params: {
        user: {
          full_name: "New Member",
          email: "new-member@example.com",
          password: "test-password"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "[role='alert']", /Password confirmation can't be blank/
  end

  test "rejects mismatched password confirmation" do
    assert_no_difference [ "User.count", "Session.count" ] do
      post registration_path, params: {
        user: {
          full_name: "New Member",
          email: "new-member@example.com",
          password: "test-password",
          password_confirmation: "different-password"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "[role='alert']", /Password confirmation doesn't match/
  end
end
