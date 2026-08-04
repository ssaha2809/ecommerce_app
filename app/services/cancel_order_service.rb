class CancelOrderService
  class CancelError < StandardError; end

  def initialize(order)
    @order = order
  end

  def call
    raise CancelError, "Order cannot be cancelled" unless @order.can_transition_to?("cancelled")

    ActiveRecord::Base.transaction do
      product_ids = @order.order_items.pluck(:product_id)
      products = Product.lock.where(id: product_ids).order(:id).index_by(&:id)

      @order.order_items.each do |item|
        product = products[item.product_id]
        next unless product
        product.update!(stock_quantity: product.stock_quantity + item.quantity)
      end

      @order.update!(status: "cancelled")
      @order
    end
  end
end
