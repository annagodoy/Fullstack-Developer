require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium,
    using: :headless_chrome,
    screen_size: [ 1400, 1000 ]

    private

    def sign_in_through_browser(user, password: "test-password")
      visit new_session_path

      within "main" do
        fill_in "Email", with: user.email
        fill_in "Password", with: password
        click_button "Sign in"
      end

      assert_current_path(user.admin? ? admin_root_path : profile_path)
    end
end
