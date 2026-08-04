class CheckoutService
  class CheckoutError < StandardError; end
  class EmptyCartError < CheckoutError; end
  class InsufficientStockError < CheckoutError; end

  def initialize(user)
    @user = user
    @cart = user.cart
  end

  def call
    raise EmptyCartError, "Cart is empty" if @cart.nil? || @cart.cart_items.empty?

    ActiveRecord::Base.transaction do
      products_by_id = lock_products!
      verify_stock!(products_by_id)
      order = build_order(products_by_id)
      decrement_stock!(products_by_id)
      @cart.cart_items.destroy_all
      order
    end
  end

  private

  def lock_products!
    product_ids = @cart.cart_items.pluck(:product_id)
    # Sort to enforce consistent locking order across concurrent checkouts and
    # avoid deadlocks.
    Product.lock.where(id: product_ids).order(:id).index_by(&:id)
  end

  def verify_stock!(products_by_id)
    @cart.cart_items.each do |item|
      product = products_by_id[item.product_id]
      next if product && product.stock_quantity >= item.quantity

      raise InsufficientStockError,
            "Insufficient stock for #{product&.name || "product ##{item.product_id}"}"
    end
  end

  def build_order(products_by_id)
    items_attrs = @cart.cart_items.map do |item|
      product = products_by_id[item.product_id]
      {
        product_id: product.id,
        quantity: item.quantity,
        unit_price_cents: product.price_cents
      }
    end

    total_cents = items_attrs.sum { |a| a[:quantity] * a[:unit_price_cents] }
    @user.orders.create!(
      status: "pending",
      total_cents: total_cents,
      customer_name: @user.name,
      customer_email: @user.email,
      order_items_attributes: items_attrs
    )
  end

  def decrement_stock!(products_by_id)
    @cart.cart_items.each do |item|
      product = products_by_id[item.product_id]
      product.update!(stock_quantity: product.stock_quantity - item.quantity)
    end
  end
end
