class OrderPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    owner_or_admin?
  end

  def create?
    true
  end

  def cancel?
    owner? && (record.pending? || record.confirmed?)
  end

  def update_status?
    user.admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin?
        scope.all
      else
        scope.where(user: user)
      end
    end
  end

  private

  def owner?
    record.user_id == user.id
  end

  def owner_or_admin?
    owner? || user.admin?
  end
end
