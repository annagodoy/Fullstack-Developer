require "application_system_test_case"

class RegistrationTest < ApplicationSystemTestCase
  test "visitor register, sign out and sign in again" do
    visit new_registration_path

    within "main" do
      fill_in "Full name", with: "Browser User"
      fill_in "Email", with: "browser-user@example.com"
      fill_in "Password", with: "browser-test-password", exact: true
      fill_in "Password confirmation", with: "browser-test-password"

      click_button "Create account"
    end

    assert_current_path profile_path
    assert_selector "#profile-full-name", text: "Browser User"
    assert_selector "#profile-email", text: "browser-user@example.com"

    within "nav[aria-label='Main navigation']" do
      assert_text "Member"
      assert_no_link "Users"
      click_button "Sign out"
    end

    assert_current_path new_session_path

    within "main" do
      fill_in "Email", with: "browser-user@example.com"
      fill_in "Password", with: "browser-test-password"
      click_button "Sign in"
    end

    assert_current_path profile_path
    assert_selector "#profile-full-name", text: "Browser User"
  end
end
