class CartPolicy < ApplicationPolicy
  def show?
    owner?
  end

  private

  def owner?
    record.respond_to?(:user_id) && record.user_id == user.id
  end
end
