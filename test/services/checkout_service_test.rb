require "test_helper"

class CheckoutServiceTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
    @category = create(:category)
    @p1 = create(:product, category: @category, price_cents: 1_000, stock_quantity: 5)
    @p2 = create(:product, category: @category, price_cents: 2_500, stock_quantity: 3)
    @cart = create(:cart, user: @user)
  end

  test "creates an order with snapshotted prices and totals" do
    create(:cart_item, cart: @cart, product: @p1, quantity: 2)
    create(:cart_item, cart: @cart, product: @p2, quantity: 1)

    order = CheckoutService.new(@user).call

    assert order.persisted?
    assert_equal @user.id, order.user_id
    assert_equal "pending", order.status
    assert_equal 2 * 1_000 + 1 * 2_500, order.total_cents
    assert_equal 2, order.order_items.count
  end

  test "snapshots current product price into order items" do
    create(:cart_item, cart: @cart, product: @p1, quantity: 1)

    order = CheckoutService.new(@user).call
    item = order.order_items.find_by(product_id: @p1.id)
    assert_equal 1_000, item.unit_price_cents

    @p1.reload.update!(price_cents: 9_999)
    assert_equal 1_000, item.reload.unit_price_cents
  end

  test "decrements product stock atomically" do
    create(:cart_item, cart: @cart, product: @p1, quantity: 2)
    create(:cart_item, cart: @cart, product: @p2, quantity: 1)

    CheckoutService.new(@user).call

    assert_equal 3, @p1.reload.stock_quantity
    assert_equal 2, @p2.reload.stock_quantity
  end

  test "clears the cart after checkout" do
    create(:cart_item, cart: @cart, product: @p1, quantity: 1)

    CheckoutService.new(@user).call
    assert_equal 0, @cart.reload.cart_items.count
  end

  test "raises EmptyCartError when cart is empty" do
    assert_raises(CheckoutService::EmptyCartError) do
      CheckoutService.new(@user).call
    end
  end

  test "raises EmptyCartError when user has no cart at all" do
    user_without_cart = create(:user)
    assert_raises(CheckoutService::EmptyCartError) do
      CheckoutService.new(user_without_cart).call
    end
  end

  test "rolls back when stock is insufficient" do
    create(:cart_item, cart: @cart, product: @p1, quantity: 5)
    @p1.update!(stock_quantity: 2) # bypasses CartItem validation by direct update

    assert_no_difference("Order.count") do
      assert_raises(CheckoutService::InsufficientStockError) do
        CheckoutService.new(@user).call
      end
    end

    assert_equal 2, @p1.reload.stock_quantity # unchanged
    assert_equal 1, @cart.reload.cart_items.count # not cleared
  end
end
