require "test_helper"

class OrderPolicyTest < ActiveSupport::TestCase
  setup do
    @admin    = create(:user, :admin)
    @owner    = create(:user)
    @other    = create(:user)
    @order    = create(:order, user: @owner)
  end

  test "owner can show own order" do
    assert OrderPolicy.new(@owner, @order).show?
  end

  test "admin can show any order" do
    assert OrderPolicy.new(@admin, @order).show?
  end

  test "other customer cannot show order" do
    refute OrderPolicy.new(@other, @order).show?
  end

  test "owner can cancel pending order" do
    assert OrderPolicy.new(@owner, @order).cancel?
  end

  test "owner can cancel confirmed order" do
    @order.update!(status: "confirmed")
    assert OrderPolicy.new(@owner, @order).cancel?
  end

  test "owner cannot cancel shipped order" do
    @order.update!(status: "confirmed")
    @order.update!(status: "shipped")
    refute OrderPolicy.new(@owner, @order).cancel?
  end

  test "other customer cannot cancel order" do
    refute OrderPolicy.new(@other, @order).cancel?
  end

  test "only admin can update status" do
    assert OrderPolicy.new(@admin, @order).update_status?
    refute OrderPolicy.new(@owner, @order).update_status?
  end

  test "scope shows customers only their own orders" do
    create(:order, user: @other)
    scoped = OrderPolicy::Scope.new(@owner, Order).resolve
    assert_equal [ @order.id ], scoped.pluck(:id)
  end

  test "scope shows admin all orders" do
    create(:order, user: @other)
    scoped = OrderPolicy::Scope.new(@admin, Order).resolve
    assert_equal 2, scoped.count
  end
end
