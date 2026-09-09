require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
    test "requires authentication" do
        get root_path

        assert_redirected_to new_session_path
    end

    test "shows the signed in user" do
        user = users(:one)
        sign_in_as(user)

        get root_path

        assert_response :success
        assert_select "p", text: "Signed in as #{user.email}"
    end
end
