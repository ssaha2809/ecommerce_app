class AddToCartService
  class InsufficientStockError < StandardError; end
  class ProductNotFoundError  < StandardError; end

  Result = Struct.new(:cart_item, :status, keyword_init: true)

  def initialize(user:, product_id:, quantity:)
    @user       = user
    @product_id = product_id
    @quantity   = quantity.to_i
  end

  # Adding to the cart must be atomic against concurrent stock checks: lock the
  # product row, verify it can satisfy the combined existing+requested quantity,
  # then upsert the cart item.
  def call
    ActiveRecord::Base.transaction do
      cart = @user.cart_or_create!
      product = Product.lock.find_by(id: @product_id)
      raise ProductNotFoundError if product.nil?

      existing = cart.cart_items.find_by(product_id: product.id)
      already_in_cart = existing&.quantity.to_i
      target_quantity = already_in_cart + @quantity

      if target_quantity > product.stock_quantity
        raise InsufficientStockError,
              "Only #{product.stock_quantity - already_in_cart} more available"
      end

      if existing
        existing.update!(quantity: target_quantity)
        Result.new(cart_item: existing, status: :updated)
      else
        item = cart.cart_items.create!(product: product, quantity: @quantity)
        Result.new(cart_item: item, status: :created)
      end
    end
  end
end
