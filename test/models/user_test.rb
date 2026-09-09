require "test_helper"

class UserTest < ActiveSupport::TestCase
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
    user = User.new(email: "new@example.com", password: "test-password")

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
end
