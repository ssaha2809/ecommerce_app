require "test_helper"

class CategoryTest < ActiveSupport::TestCase
  test "valid category can be built from factory" do
    assert build(:category).valid?
  end

  test "requires a name" do
    category = build(:category, name: nil)
    assert_not category.valid?
    assert_includes category.errors[:name], "can't be blank"
  end

  test "name must be unique" do
    create(:category, name: "Electronics")
    duplicate = build(:category, name: "Electronics")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:name], "has already been taken"
  end

  test "has many products" do
    category = create(:category)
    p1 = create(:product, category: category)
    p2 = create(:product, category: category)
    assert_equal [ p1, p2 ].sort, category.products.to_a.sort
  end

  test "destroying category with products is restricted" do
    category = create(:category)
    create(:product, category: category)
    assert_not category.destroy
    assert_includes category.errors[:base].join, "Cannot delete"
  end
end
