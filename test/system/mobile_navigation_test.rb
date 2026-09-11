require "application_system_test_case"

class MobileNavigationTest < ApplicationSystemTestCase
  setup do
    page.current_window.resize_to(430, 932)
  end

  teardown do
    page.current_window.resize_to(1400, 1000)
  end

  test "admin can navigate and edit a user on a narrow screen" do
    admin = users(:one)

    admin.update!(role: :admin)

    sign_in_through_browser(admin)

    assert_selector "#total-users"
    assert_page_fits_viewport

    within "nav[aria-label='Main navigation']" do
      click_link "Users"
    end

    assert_current_path admin_users_path
    assert_page_fits_viewport

    within "#user_#{users(:two).id}" do
      click_link "Edit"
    end

    assert_current_path edit_admin_user_path(users(:two))
    assert_page_fits_viewport

    within "main" do
      fill_in "Full name", with: "Mobile Member"
      click_button "Save"
    end

    assert_current_path admin_users_path
    assert_selector "#user_#{users(:two).id}", text: "Mobile Member"
    assert_page_fits_viewport
  end

  private

  def assert_page_fits_viewport
    dimensions = page.evaluate_script(<<~JS)
      ({
        content: document.documentElement.scrollWidth,
        viewport: document.documentElement.clientWidth
      })
    JS

    assert_operator dimensions["content"], :<=, dimensions["viewport"],
      "The page overflows horizontally"
  end
end
