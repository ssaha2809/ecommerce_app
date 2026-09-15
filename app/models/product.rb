class Product < ApplicationRecord
  belongs_to :category
  has_many :order_items, dependent: :restrict_with_error
  has_many :orders, through: :order_items
  has_many :cart_items, dependent: :destroy

  validates :name, presence: true
  validates :sku, presence: true, uniqueness: true
  validates :price_cents, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :stock_quantity, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  SORT_OPTIONS = {
    "price_asc"  => { price_cents: :asc },
    "price_desc" => { price_cents: :desc },
    "name_asc"   => { name: :asc },
    "name_desc"  => { name: :desc },
    "newest"     => { created_at: :desc },
    "oldest"     => { created_at: :asc }
  }.freeze

  scope :by_category, ->(id) { where(category_id: id) if id.present? }

  scope :price_between, ->(min_cents, max_cents) {
    rel = all
    rel = rel.where("price_cents >= ?", min_cents.to_i) if min_cents.present?
    rel = rel.where("price_cents <= ?", max_cents.to_i) if max_cents.present?
    rel
  }

  scope :search, ->(q) {
    if q.present?
      where("LOWER(name) LIKE ?", "%#{sanitize_sql_like(q.to_s.downcase)}%")
    end
  }

  scope :sorted_by, ->(key) {
    order(SORT_OPTIONS.fetch(key, SORT_OPTIONS["newest"]))
  }

  # Dollar-facing accessor for the web form / legacy callers.
  # The canonical column is price_cents; never read it for range queries.
  def price
    price_cents / 100.0
  end

  def price=(dollars)
    self.price_cents = dollars.present? ? (dollars.to_d * 100).to_i : nil
  end
end
