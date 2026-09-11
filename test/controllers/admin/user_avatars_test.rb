require "test_helper"

class Admin::UserAvatarsTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:one)
    @admin.update!(role: :admin)

    @user = users(:two)
    @user.avatar_image.attach(avatar_upload)
  end

  test "admins can create users with an avatar" do
    sign_in_as(@admin)

    assert_difference "User.count", 1 do
      post admin_users_path, params: {
        user: {
          full_name: "Avatar User",
          email: "avatar-user@example.com",
          password: "test-password",
          role: "member",
          avatar_image: avatar_upload
        }
      }
    end

    assert_redirected_to admin_users_path
    assert User.find_by!(email: "avatar-user@example.com")
      .avatar_image.attached?
  end

  test "admins can replace an avatar" do
    sign_in_as(@admin)

    original_blob_id = @user.avatar_image.blob_id

    patch admin_user_path(@user), params: {
      user: {
        avatar_image: avatar_upload
      }
    }

    assert_redirected_to admin_users_path
    assert_not_equal original_blob_id, @user.reload.avatar_image.blob_id
    assert_equal file_fixture("avatar.png").binread,
      @user.avatar_image.download
  end

  test "invalid uploads keeps the existing avatar" do
    sign_in_as(@admin)

    original_blob_id = @user.avatar_image.blob_id

    patch admin_user_path(@user), params: {
      user: {
        avatar_image: fixture_file_upload("users.csv", "text/csv")
      }
    }

    assert_response :unprocessable_entity
    assert_equal original_blob_id, @user.reload.avatar_image.blob_id
    assert_select "[role='alert']", text: /must be a JPEG or PNG/
  end

  test "admins can view users avatar" do
    sign_in_as(@admin)

    get avatar_admin_user_path(@user)

    assert_response :success
    assert_equal "image/png", response.media_type
    assert_equal file_fixture("avatar.png").binread, response.body
    assert_includes response.headers["Cache-Control"], "private"
    assert_includes response.headers["Cache-Control"], "no-store"
  end

  test "admins receive not found when the user has no avatar" do
    sign_in_as(@admin)

    get avatar_admin_user_path(@admin)

    assert_response :not_found
  end

  test "admins can remove an avatar without delete user" do
    sign_in_as(@admin)

    assert_no_difference "User.count" do
      delete avatar_admin_user_path(@user)
    end

    assert_redirected_to edit_admin_user_path(@user)
    assert_not @user.reload.avatar_image.attached?
  end

  test "members cant view or remove avatars" do
    sign_in_as(@user)

    get avatar_admin_user_path(@user)

    assert_response :forbidden

    sign_in_as(@user)

    assert_no_changes -> { @user.reload.avatar_image.blob_id } do
      delete avatar_admin_user_path(@user)
    end

    assert_response :forbidden
  end

  test "visitors cant view or remove avatars" do
    get avatar_admin_user_path(@user)

    assert_redirected_to new_session_path

    assert_no_changes -> { @user.reload.avatar_image.blob_id } do
      delete avatar_admin_user_path(@user)
    end

    assert_redirected_to new_session_path
  end

  private

  def avatar_upload
    fixture_file_upload("avatar.png", "image/png")
  end
end
