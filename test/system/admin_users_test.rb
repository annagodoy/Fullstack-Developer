require "application_system_test_case"

class AdminUsersTest < ApplicationSystemTestCase
  setup do
    @admin = users(:one)
    @admin.update!(role: :admin)
    sign_in_through_browser(@admin)
  end

  test "admin create, edit and delete a user" do
    within "nav[aria-label='Main navigation']" do
      click_link "Users"
    end

    click_link "New user"

    within "main" do
      fill_in "Full name", with: "Browser Member"
      fill_in "Email", with: "managed-user@example.com"
      fill_in "Initial password", with: "browser-test-password"
      select "Member", from: "Role"
      attach_file "Avatar", file_fixture("avatar.png")
      click_button "Save"
    end

    assert_current_path admin_users_path
    assert_selector "tbody tr", text: "managed-user@example.com"

    user = User.find_by!(email: "managed-user@example.com")

    within "#user_#{user.id}" do
      assert_text "Browser Member"
      assert_text "Member"
      click_link "Edit"
    end

    assert_current_path edit_admin_user_path(user)
    assert_selector "img[alt='Current avatar']"
    assert_no_selector "input[type='password']"

    within "main" do
      fill_in "Full name", with: "Browser Admin"
      select "Admin", from: "Role"
      click_button "Save"
    end

    assert_current_path admin_users_path

    within "#user_#{user.id}" do
      assert_text "Browser Admin"
      assert_selector ".badge", text: "Admin", exact_text: true
    end

    assert user.reload.admin?
    assert user.authenticate("browser-test-password")

    accept_confirm do
      within "#user_#{user.id}" do
        click_button "Delete"
      end
    end

    assert_no_selector "#user_#{user.id}"
    assert_not User.exists?(user.id)
    assert User.exists?(@admin.id)
  end

  test "admin removes a user avatar" do
    user = users(:two)

    File.open(file_fixture("avatar.png"), "rb") do |file|
      user.avatar_image.attach(
        io: file,
        filename: "avatar.png",
        content_type: "image/png"
      )
    end

    visit edit_admin_user_path(user)

    assert_selector "img[alt='Current avatar']"

    accept_confirm do
      click_button "Remove avatar"
    end

    assert_current_path edit_admin_user_path(user)
    assert_no_selector "img[alt='Current avatar']"
    assert_selector "[role='status']", text: "Avatar removed."
    assert_not user.reload.avatar_image.attached?
  end
end
