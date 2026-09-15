class Cart < ApplicationRecord
  belongs_to :user
  has_many :cart_items, dependent: :destroy
  has_many :products, through: :cart_items

  validates :user_id, uniqueness: true

  def total_cents
    cart_items.sum(&:subtotal_cents)
  end
end
