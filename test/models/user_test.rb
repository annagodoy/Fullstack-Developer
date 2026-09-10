require "test_helper"

class UserTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include ActionCable::TestHelper

  test "downcases and strips email" do
    user = User.new(email: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email)
  end

  test "requires an email" do
    user = User.new(email: "", password: "test-password")

    assert_not user.valid?
    assert user.errors.added?(:email, :blank)
  end

  test "rejects an invalid email" do
    user = User.new(email: "invalid", password: "test-password")

    assert_not user.valid?
    assert user.errors.added?(:email, :invalid, value: "invalid")
  end

  test "rejects a duplicated email" do
    user = User.new(
      email: "#{users(:one).email}",
      password: "test-password"
    )

    assert_not user.valid?
    assert user.errors.added?(:email, :taken, value: users(:one).email)
  end

  test "rejects an short password" do
    user = User.new(email: "new@example.com", password: "short")

    assert_not user.valid?
    assert user.errors.added?(:password, :too_short, count: 12)
  end

  test "accepts a valid password" do
    user = User.new(full_name: "New Member", email: "new@example.com", password: "test-password")

    assert user.valid?
  end

  test "allows updating email without changing password" do
    user = users(:one)
    current_password_digest = user.password_digest

    assert user.update(email: "new-email@example.com")
    assert_equal current_password_digest, user.reload.password_digest
  end

  test "new users default to member" do
    user = User.create!(
      full_name: "New Member",
      email: "member@example.com",
      password: "test-password"
    )

    assert user.reload.member?
    assert_not user.admin?
  end

  test "persists the admin role" do
    user = users(:one)
    user.update!(role: :admin)

    assert user.reload.admin?
  end

  test "rejects an invalid role" do
    user = users(:one)
    user.role = "invalid"

    assert_not user.valid?
    assert user.errors.added?(:role, :inclusion, value: "invalid")
  end

  test "strips full name" do
    user = User.new(full_name: "  John Doe  ")
    assert_equal("John Doe", user.full_name)
  end

  test "requires a full name" do
    user = User.new(
      full_name: "",
      email: "new@example.com",
      password: "test-password"
    )

    assert_not user.valid?
    assert user.errors.added?(:full_name, :blank)
  end

  test "rejects unsupported avatar formats" do
    user = users(:one)
    user.avatar_image = {
      io: StringIO.new("plain text"),
      filename: "avatar.txt",
      content_type: "text/plain"
    }

    assert_not user.valid?
    assert_includes user.errors[:avatar_image], "must be a JPEG or PNG"
  end

  test "rejects images larger than 5MB" do
    user = users(:one)

    user.avatar_image = {
      io: StringIO.new("x" * (5.megabytes + 1)),
      filename: "large.txt",
      content_type: "text/plain"
    }

    assert_not user.valid?
    assert_includes user.errors[:avatar_image], "must be 5MB or smaller"
  end

  test "create a user refresh the admin dashboard" do
    assert_dashboard_refresh do
      User.create!(
        full_name: "New Member",
        email: "new-member@example.com",
        password: "test-password"
      )
    end
  end

  test "delete a user refresh the admin dashboard" do
    assert_dashboard_refresh do
      users(:two).destroy!
    end
  end

  test "change a user role refresh the admin dashboard" do
    assert_dashboard_refresh do
      users(:two).update!(role: :admin)
    end
  end

  test "change a user name dont refresh the admin dashboard" do
    assert_no_enqueued_jobs(only: Turbo::Streams::BroadcastStreamJob) do
      users(:two).update!(full_name: "Updated Name")
    end
  end

  test "invalid user creation dont refresh the admin dashboard" do
    assert_no_enqueued_jobs(only: Turbo::Streams::BroadcastStreamJob) do
      user = User.new(email: "invalid")

      assert_not user.save
    end
  end

  private

  def assert_dashboard_refresh
    messages = capture_broadcasts("admin_dashboard") do
      perform_enqueued_jobs(only: Turbo::Streams::BroadcastStreamJob) do
        yield
      end
    end

    assert_equal 1, messages.size

    stream = Nokogiri::HTML.fragment(messages.first).at_css("turbo-stream")
    assert_equal "refresh", stream&.[]("action")
  end
end
