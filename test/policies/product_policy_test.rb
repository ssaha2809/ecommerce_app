require "test_helper"

class ProductPolicyTest < ActiveSupport::TestCase
  setup do
    @admin    = create(:user, :admin)
    @customer = create(:user)
    @product  = build(:product)
  end

  test "anyone can index" do
    assert ProductPolicy.new(@admin, Product).index?
    assert ProductPolicy.new(@customer, Product).index?
  end

  test "anyone can show" do
    assert ProductPolicy.new(@admin, @product).show?
    assert ProductPolicy.new(@customer, @product).show?
  end

  test "admin can create products" do
    assert ProductPolicy.new(@admin, @product).create?
  end

  test "customer cannot create products" do
    refute ProductPolicy.new(@customer, @product).create?
  end

  test "admin can update products" do
    assert ProductPolicy.new(@admin, @product).update?
  end

  test "customer cannot update products" do
    refute ProductPolicy.new(@customer, @product).update?
  end

  test "admin can destroy products" do
    assert ProductPolicy.new(@admin, @product).destroy?
  end

  test "customer cannot destroy products" do
    refute ProductPolicy.new(@customer, @product).destroy?
  end
end
