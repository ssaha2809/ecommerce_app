require "test_helper"

class CartTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
    @category = create(:category)
  end

  test "is valid with a user" do
    assert build(:cart, user: @user).valid?
  end

  test "requires unique user" do
    create(:cart, user: @user)
    duplicate = build(:cart, user: @user)
    refute duplicate.valid?
    assert_includes duplicate.errors.full_messages.join, "User"
  end

  test "total_cents sums subtotals across items" do
    cart = create(:cart, user: @user)
    p1 = create(:product, category: @category, price_cents: 1000, stock_quantity: 10)
    p2 = create(:product, category: @category, price_cents: 500,  stock_quantity: 10)
    create(:cart_item, cart: cart, product: p1, quantity: 2) # 2000
    create(:cart_item, cart: cart, product: p2, quantity: 3) # 1500

    assert_equal 3_500, cart.total_cents
  end

  test "destroying cart cascades to items" do
    cart = create(:cart, user: @user)
    product = create(:product, category: @category)
    create(:cart_item, cart: cart, product: product)

    assert_difference("CartItem.count", -1) do
      cart.destroy
    end
  end
end
