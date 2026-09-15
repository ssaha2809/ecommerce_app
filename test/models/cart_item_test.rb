require "test_helper"

class CartItemTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
    @category = create(:category)
    @product = create(:product, category: @category, price_cents: 2_500, stock_quantity: 5)
    @cart = create(:cart, user: @user)
  end

  test "is valid with positive quantity within stock" do
    assert build(:cart_item, cart: @cart, product: @product, quantity: 3).valid?
  end

  test "requires positive quantity" do
    item = build(:cart_item, cart: @cart, product: @product, quantity: 0)
    refute item.valid?
    assert_includes item.errors[:quantity], "must be greater than 0"
  end

  test "rejects quantity exceeding stock" do
    item = build(:cart_item, cart: @cart, product: @product, quantity: 10)
    refute item.valid?
    assert_match(/exceeds available stock/, item.errors[:quantity].join)
  end

  test "rejects duplicate product in the same cart" do
    create(:cart_item, cart: @cart, product: @product, quantity: 1)
    duplicate = build(:cart_item, cart: @cart, product: @product, quantity: 1)
    refute duplicate.valid?
  end

  test "subtotal_cents multiplies quantity by current product price" do
    item = build(:cart_item, cart: @cart, product: @product, quantity: 2)
    assert_equal 5_000, item.subtotal_cents
  end
end
