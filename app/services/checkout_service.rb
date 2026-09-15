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
      lines = locked_lines
      verify_stock!(lines)
      order = create_order(lines)
      decrement_stock!(lines)
      @cart.cart_items.destroy_all
      order
    end
  end

  private

  # Pair each cart item with its locked product.
  def locked_lines
    items = @cart.cart_items.to_a
    # Sort to enforce consistent locking order across concurrent checkouts and
    # avoid deadlocks.
    products_by_id = Product.lock
                            .where(id: items.map(&:product_id))
                            .order(:id)
                            .index_by(&:id)

    items.map do |item|
      product = products_by_id[item.product_id] ||
        raise(InsufficientStockError, "Product ##{item.product_id} is no longer available")
      [ item, product ]
    end
  end

  def verify_stock!(lines)
    lines.each do |item, product|
      next if product.stock_quantity >= item.quantity

      raise InsufficientStockError, "Insufficient stock for #{product.name}"
    end
  end

  def create_order(lines)
    order_items = lines.map do |item, product|
      OrderItem.new(product: product, quantity: item.quantity, unit_price_cents: product.price_cents)
    end

    @user.orders.create!(
      status: "pending",
      total_cents: order_items.sum(&:subtotal_cents),
      customer_name: @user.name,
      customer_email: @user.email,
      order_items: order_items
    )
  end

  def decrement_stock!(lines)
    lines.each do |item, product|
      product.update!(stock_quantity: product.stock_quantity - item.quantity)
    end
  end
end
