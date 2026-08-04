require "test_helper"

class CategoryPolicyTest < ActiveSupport::TestCase
  setup do
    @admin    = create(:user, :admin)
    @customer = create(:user)
  end

  test "anyone can index" do
    assert CategoryPolicy.new(@admin, Category).index?
    assert CategoryPolicy.new(@customer, Category).index?
  end

  test "no one can write through default policy" do
    category = build(:category)
    refute CategoryPolicy.new(@admin, category).create?
    refute CategoryPolicy.new(@admin, category).update?
    refute CategoryPolicy.new(@admin, category).destroy?
  end
end
