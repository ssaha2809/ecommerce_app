require "test_helper"

class AddToCartServiceTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
    @category = create(:category)
    @product = create(:product, category: @category, price_cents: 1_000, stock_quantity: 5)
  end

  test "creates a cart on first add" do
    assert_nil @user.cart
    AddToCartService.new(user: @user, product_id: @product.id, quantity: 2).call
    assert @user.reload.cart.present?
    assert_equal 2, @user.cart.cart_items.first.quantity
  end

  test "increments quantity when product already in cart" do
    AddToCartService.new(user: @user, product_id: @product.id, quantity: 1).call
    AddToCartService.new(user: @user, product_id: @product.id, quantity: 2).call

    assert_equal 1, @user.cart.cart_items.count
    assert_equal 3, @user.cart.cart_items.first.quantity
  end

  test "rejects add when stock insufficient" do
    assert_raises(AddToCartService::InsufficientStockError) do
      AddToCartService.new(user: @user, product_id: @product.id, quantity: 6).call
    end
    assert_nil @user.cart&.cart_items&.first
  end

  test "rejects further add that would exceed stock" do
    AddToCartService.new(user: @user, product_id: @product.id, quantity: 4).call
    assert_raises(AddToCartService::InsufficientStockError) do
      AddToCartService.new(user: @user, product_id: @product.id, quantity: 2).call
    end
    assert_equal 4, @user.cart.cart_items.first.quantity
  end

  test "raises ProductNotFound for invalid product id" do
    assert_raises(AddToCartService::ProductNotFoundError) do
      AddToCartService.new(user: @user, product_id: 99_999, quantity: 1).call
    end
  end

  test "rolls back when stock check fails mid-transaction" do
    other_user = create(:user)
    AddToCartService.new(user: other_user, product_id: @product.id, quantity: 5).call
    @product.update!(stock_quantity: 0)

    assert_raises(AddToCartService::InsufficientStockError) do
      AddToCartService.new(user: @user, product_id: @product.id, quantity: 1).call
    end
    refute CartItem.exists?(cart_id: @user.cart&.id)
  end
end
