require "test_helper"

class ProductTest < ActiveSupport::TestCase
  test "valid product can be built from factory" do
    assert build(:product).valid?
  end

  test "requires a name" do
    product = build(:product, name: nil)
    assert_not product.valid?
    assert_includes product.errors[:name], "can't be blank"
  end

  test "requires an sku" do
    product = build(:product, sku: nil)
    assert_not product.valid?
    assert_includes product.errors[:sku], "can't be blank"
  end

  test "sku must be unique" do
    create(:product, sku: "SKU-DUP")
    duplicate = build(:product, sku: "SKU-DUP")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:sku], "has already been taken"
  end

  test "requires price_cents" do
    product = build(:product, price_cents: nil)
    assert_not product.valid?
    assert_includes product.errors[:price_cents], "can't be blank"
  end

  test "price_cents must be greater than zero" do
    [ 0, -1, -100 ].each do |bad|
      product = build(:product, price_cents: bad)
      assert_not product.valid?, "expected price_cents=#{bad} to be invalid"
      assert_includes product.errors[:price_cents], "must be greater than 0"
    end
  end

  test "price_cents must be an integer" do
    product = build(:product, price_cents: 9.5)
    assert_not product.valid?
    assert_includes product.errors[:price_cents], "must be an integer"
  end

  test "stock_quantity must be non-negative" do
    product = build(:product, stock_quantity: -1)
    assert_not product.valid?
    assert_includes product.errors[:stock_quantity], "must be greater than or equal to 0"
  end

  test "out_of_stock trait sets stock to zero" do
    product = build(:product, :out_of_stock)
    assert_equal 0, product.stock_quantity
    assert product.valid?
  end

  test "requires a category" do
    product = build(:product, category: nil)
    assert_not product.valid?
    assert_includes product.errors[:category], "must exist"
  end

  test "belongs to a category" do
    category = create(:category)
    product = create(:product, category: category)
    assert_equal category, product.category
  end
end
