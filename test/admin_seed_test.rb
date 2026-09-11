require "test_helper"

class AdminSeedTest < ActiveSupport::TestCase
  setup do
    @original_env = ENV.to_h.slice(
      "ADMIN_FULL_NAME", "ADMIN_EMAIL", "ADMIN_PASSWORD"
    )

    ENV["ADMIN_FULL_NAME"] = "Seed Admin"
    ENV["ADMIN_EMAIL"] = "seed-admin@example.com"
    ENV["ADMIN_PASSWORD"] = "seed-test-password"
  end

  teardown do
    %w[ADMIN_FULL_NAME ADMIN_EMAIL ADMIN_PASSWORD].each do |key|
      ENV[key] = @original_env[key]
    end
  end

  test "creates an administrator" do
    assert_difference "User.count", 1 do
      run_seed
    end

    admin = User.find_by!(email: "seed-admin@example.com")

    assert admin.admin?
    assert_equal "Seed Admin", admin.full_name
    assert admin.authenticate("seed-test-password")
  end

  test "repeated execution preserves the existing administrator" do
    run_seed
    admin = User.find_by!(email: "seed-admin@example.com")

    ENV["ADMIN_FULL_NAME"] = "Changed Name"
    ENV["ADMIN_PASSWORD"] = "another-test-password"

    assert_no_changes -> { admin.reload.attributes } do
      assert_no_difference "User.count" do
        run_seed
      end
    end

    assert admin.authenticate("seed-test-password")
  end

  test "does not promote an existing member" do
    member = users(:two)
    ENV["ADMIN_EMAIL"] = member.email

    assert_no_changes -> { member.reload.attributes } do
      assert_no_difference "User.count" do
        assert_raises(ArgumentError) { run_seed }
      end
    end
  end

  test "skips creation when no variables are supplied" do
    %w[ADMIN_FULL_NAME ADMIN_EMAIL ADMIN_PASSWORD].each do |key|
      ENV.delete(key)
    end

    assert_no_difference "User.count" do
      run_seed
    end
  end

  test "rejects incomplete configuration" do
    ENV.delete("ADMIN_PASSWORD")

    assert_no_difference "User.count" do
      assert_raises(ArgumentError) { run_seed }
    end
  end

  private

  def run_seed
    capture_io do
      load Rails.root.join("db/seeds.rb").to_s
    end
  end
end
