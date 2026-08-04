require "test_helper"

class OrderTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
  end

  test "valid order with user and zero total" do
    assert build(:order, user: @user).valid?
  end

  test "default status is pending" do
    order = Order.new(user: @user, total_cents: 0)
    assert_equal "pending", order.status
    assert order.pending?
  end

  test "enum scopes work" do
    pending   = create(:order, user: @user)
    delivered = create(:order, user: create(:user), status: "confirmed")
    delivered.update!(status: "shipped")
    delivered.update!(status: "delivered")

    assert_includes Order.pending,   pending
    assert_includes Order.delivered, delivered
  end

  test "allowed transition pending -> confirmed" do
    order = create(:order, user: @user)
    assert order.update(status: "confirmed")
  end

  test "rejects transition delivered -> pending" do
    order = create(:order, user: @user)
    order.update!(status: "confirmed")
    order.update!(status: "shipped")
    order.update!(status: "delivered")

    refute order.update(status: "pending")
    assert_match(/cannot transition/, order.errors[:status].join)
  end

  test "rejects transition pending -> shipped (skipping confirmed)" do
    order = create(:order, user: @user)
    refute order.update(status: "shipped")
  end

  test "can_transition_to? mirrors the allowed map" do
    order = create(:order, user: @user)
    assert order.can_transition_to?("confirmed")
    refute order.can_transition_to?("delivered")
  end

  test "recalculate_total! sums snapshotted prices" do
    order = create(:order, user: @user)
    category = create(:category)
    p1 = create(:product, category: category, price_cents: 1_000)
    p2 = create(:product, category: category, price_cents: 2_500)
    create(:order_item, order: order, product: p1, unit_price_cents: 1_000, quantity: 2)
    create(:order_item, order: order, product: p2, unit_price_cents: 2_500, quantity: 1)

    order.recalculate_total!
    assert_equal 4_500, order.reload.total_cents
  end
end
