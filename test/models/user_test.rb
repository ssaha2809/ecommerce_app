require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "valid user can be built from factory" do
    assert build(:user).valid?
  end

  test "requires email" do
    user = build(:user, email: nil)
    assert_not user.valid?
    assert_includes user.errors[:email], "can't be blank"
  end

  test "email must be unique" do
    create(:user, email: "dup@example.com")
    duplicate = build(:user, email: "dup@example.com")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:email], "has already been taken"
  end

  test "email uniqueness is case-insensitive" do
    create(:user, email: "MixedCase@Example.com")
    duplicate = build(:user, email: "mixedcase@example.com")
    assert_not duplicate.valid?
  end

  test "requires name" do
    user = build(:user, name: nil)
    assert_not user.valid?
    assert_includes user.errors[:name], "can't be blank"
  end

  test "default role is customer" do
    user = create(:user)
    assert user.customer?
    assert_not user.admin?
  end

  test "admin trait creates admin user" do
    admin = create(:user, :admin)
    assert admin.admin?
  end

  test "raises on invalid role assignment" do
    assert_raises(ArgumentError) do
      build(:user, role: :wizard)
    end
  end

  test "auto-generates an api_token if not provided" do
    user = User.new(name: "X", email: "x@example.com", role: :customer)
    user.valid?
    assert_predicate user.api_token, :present?
  end

  test "api_token must be unique" do
    create(:user, api_token: "shared-token")
    duplicate = build(:user, api_token: "shared-token")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:api_token], "has already been taken"
  end
end
