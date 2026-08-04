class Order < ApplicationRecord
  STATUSES = %w[pending confirmed shipped delivered cancelled].freeze

  # Status is stored as a string column (legacy schema). Map symbols → strings
  # so we still get bang predicates (`order.confirmed!`) and scopes
  # (`Order.pending`) without changing storage.
  enum :status, STATUSES.index_with(&:itself), default: "pending"

  ALLOWED_TRANSITIONS = {
    "pending"   => %w[confirmed cancelled],
    "confirmed" => %w[shipped cancelled],
    "shipped"   => %w[delivered],
    "delivered" => [],
    "cancelled" => []
  }.freeze

  belongs_to :user
  has_many :order_items, dependent: :destroy
  has_many :products, through: :order_items

  accepts_nested_attributes_for :order_items

  validates :total_cents, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate  :status_transition_allowed, on: :update

  def can_transition_to?(new_status)
    # During validation `status` is already the new value, so prefer
    # `status_was` (the persisted value) when one is set.
    from = status_changed? ? status_was : status
    ALLOWED_TRANSITIONS.fetch(from.to_s, []).include?(new_status.to_s)
  end

  def recalculate_total!
    self.total_cents = order_items.sum { |i| i.quantity * i.unit_price_cents }
    save!
  end

  private

  def status_transition_allowed
    return unless status_changed?
    previous = status_was
    return if previous.blank? # newly created records are validated elsewhere
    return if can_transition_to?(status)

    errors.add(:status, "cannot transition from #{previous} to #{status}")
  end
end
