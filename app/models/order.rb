class Order < ApplicationRecord
  has_many :order_items, dependent: :destroy
  has_many :products, through: :order_items

  ## allow_destroy: true = related model can be destroyed, handy rails feature

  accepts_nested_attributes_for :order_items, allow_destroy: true, reject_if: proc { |attributes| attributes['product_id'].blank? }

  validates :customer_name, presence: true
  validates :customer_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  before_save :calculate_total
  after_save :recalculate_total_if_needed

  def calculate_total_amount
    order_items.reload if persisted?
    order_items.sum { |item| (item.quantity || 0) * (item.unit_price || 0) }
  end

  private

  def calculate_total
    if order_items.any?
      self.total_amount = order_items.sum { |item| (item.quantity || 0) * (item.unit_price || 0) }
    end
  end

  def recalculate_total_if_needed
    # Recalculate after order items are saved
    calculated = calculate_total_amount
    if calculated != total_amount
      update_column(:total_amount, calculated)
    end
  end
end
