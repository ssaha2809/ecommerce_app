class CartItemPolicy < ApplicationPolicy
  def create?
    true
  end

  def update?
    owner?
  end

  def destroy?
    owner?
  end

  private

  def owner?
    record.cart.user_id == user.id
  end
end
