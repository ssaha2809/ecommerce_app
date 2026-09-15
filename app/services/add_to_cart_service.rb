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
    raise ArgumentError, "quantity must be positive" unless @quantity.positive?

    ActiveRecord::Base.transaction do
      product = locked_product
      cart    = @user.find_or_create_cart!
      # Built via CartItem.new rather than cart.cart_items.build/find_or_initialize_by:
      # the latter caches the unsaved record on the association's loaded target,
      # which survives a transaction rollback and leaves a phantom in-memory item.
      item    = cart.cart_items.find_by(product_id: product.id) || CartItem.new(cart: cart, product_id: product.id)

      current_quantity = item.persisted? ? item.quantity : 0
      item.quantity    = current_quantity + @quantity
      ensure_stock!(product, item.quantity, current_quantity)

      status = item.new_record? ? :created : :updated
      item.save!

      Result.new(cart_item: item, status: status)
    end
  end

  private

  def locked_product
    Product.lock.find_by(id: @product_id) or raise ProductNotFoundError
  end

  def ensure_stock!(product, target, current_quantity)
    return if target <= product.stock_quantity

    raise InsufficientStockError,
          "Only #{product.stock_quantity - current_quantity} more available"
  end
end
