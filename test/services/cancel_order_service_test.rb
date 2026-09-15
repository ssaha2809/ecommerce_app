require "test_helper"

class CancelOrderServiceTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
    @category = create(:category)
    @product = create(:product, category: @category, price_cents: 1_000, stock_quantity: 5)
    @cart = create(:cart, user: @user)
    create(:cart_item, cart: @cart, product: @product, quantity: 2)
    @order = CheckoutService.new(@user).call
  end

  test "cancelling restores stock" do
    assert_equal 3, @product.reload.stock_quantity # checkout decremented from 5
    CancelOrderService.new(@order).call
    assert_equal 5, @product.reload.stock_quantity
  end

  test "cancelling marks the order cancelled" do
    CancelOrderService.new(@order).call
    assert_equal "cancelled", @order.reload.status
  end

  test "raises when order cannot be cancelled" do
    @order.update!(status: "confirmed")
    @order.update!(status: "shipped")
    @order.update!(status: "delivered")

    assert_raises(CancelOrderService::CancelError) do
      CancelOrderService.new(@order).call
    end
    assert_equal 3, @product.reload.stock_quantity # not restored
  end
end
