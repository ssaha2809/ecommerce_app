require "test_helper"

class CartPolicyTest < ActiveSupport::TestCase
  setup do
    @owner   = create(:user)
    @other   = create(:user)
    @cart    = create(:cart, user: @owner)
  end

  test "owner can show cart" do
    assert CartPolicy.new(@owner, @cart).show?
  end

  test "non-owner cannot show cart" do
    refute CartPolicy.new(@other, @cart).show?
  end
end

class CartItemPolicyTest < ActiveSupport::TestCase
  setup do
    @owner    = create(:user)
    @other    = create(:user)
    @category = create(:category)
    @product  = create(:product, category: @category)
    @cart     = create(:cart, user: @owner)
    @item     = create(:cart_item, cart: @cart, product: @product)
  end

  test "any user can attempt create (which is then constrained by service)" do
    assert CartItemPolicy.new(@owner, CartItem).create?
    assert CartItemPolicy.new(@other, CartItem).create?
  end

  test "owner can update and destroy" do
    assert CartItemPolicy.new(@owner, @item).update?
    assert CartItemPolicy.new(@owner, @item).destroy?
  end

  test "non-owner cannot update or destroy" do
    refute CartItemPolicy.new(@other, @item).update?
    refute CartItemPolicy.new(@other, @item).destroy?
  end
end
