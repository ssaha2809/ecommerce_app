require "test_helper"

class OrderItemTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
    @category = create(:category)
    @product = create(:product, category: @category, price_cents: 1_500)
    @order = create(:order, user: @user)
  end

  test "valid with positive quantity and unit_price_cents" do
    assert build(:order_item, order: @order, product: @product, quantity: 2, unit_price_cents: 1_500).valid?
  end

  test "requires positive quantity" do
    item = build(:order_item, order: @order, product: @product, quantity: 0)
    refute item.valid?
  end

  test "requires non-negative unit_price_cents" do
    item = build(:order_item, order: @order, product: @product, unit_price_cents: -1)
    refute item.valid?
  end

  test "subtotal_cents multiplies quantity by snapshot price (not current product price)" do
    item = create(:order_item, order: @order, product: @product, quantity: 3, unit_price_cents: 1_500)
    @product.update!(price_cents: 9_999)

    assert_equal 4_500, item.subtotal_cents
  end
end
