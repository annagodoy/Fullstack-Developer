require "application_system_test_case"

class ProfileTest < ApplicationSystemTestCase
  setup do
    @user = users(:two)
    sign_in_through_browser(@user)
  end

  test "member edit profile and upload an avatar" do
    click_link "Edit profile"

    assert_current_path edit_profile_path

    within "main" do
      fill_in "Full name", with: "Updated Member"
      fill_in "Email", with: "updated-member@example.com"
      attach_file "Avatar", file_fixture("avatar.png")

      click_button "Save"
    end

    assert_current_path profile_path
    assert_selector "#profile-full-name", text: "Updated Member"
    assert_selector "#profile-email", text: "updated-member@example.com"
    assert_selector "img[alt='Avatar image']"

    assert @user.reload.avatar_image.attached?
    assert_equal "updated-member@example.com", @user.email
  end

  test "member can cancel account deletion" do
    dismiss_confirm do
      click_button "Delete profile"
    end

    assert_current_path profile_path
    assert_selector "#profile-full-name", text: @user.full_name
    assert User.exists?(@user.id)
  end

  test "member deletes account and is signed out" do
    accept_confirm do
      click_button "Delete profile"
    end

    assert_current_path new_session_path
    assert_not User.exists?(@user.id)
    assert_not Session.exists?(user_id: @user.id)

    visit profile_path

    assert_current_path new_session_path
    assert_selector "h1", text: "Sign in"
  end
end
