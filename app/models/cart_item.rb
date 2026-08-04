class CartItem < ApplicationRecord
  belongs_to :cart
  belongs_to :product

  validates :quantity, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :product_id, uniqueness: { scope: :cart_id }
  validate  :quantity_within_stock

  def subtotal_cents
    (quantity || 0) * (product&.price_cents || 0)
  end

  private

  def quantity_within_stock
    return if product.nil? || quantity.blank?
    return if quantity <= product.stock_quantity

    errors.add(:quantity, "exceeds available stock (#{product.stock_quantity})")
  end
end
