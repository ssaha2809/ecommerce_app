module Api
  module V1
    class CartsController < BaseController
      # GET /api/v1/cart
      def show
        cart = current_user.cart_or_create!
        authorize cart
        render json: serialize_cart(cart), status: :ok
      end

      private

      def serialize_cart(cart)
        items = cart.cart_items.includes(:product).map do |item|
          {
            id: item.id,
            product_id: item.product_id,
            product_name: item.product.name,
            quantity: item.quantity,
            unit_price_cents: item.product.price_cents,
            subtotal_cents: item.subtotal_cents
          }
        end

        {
          id: cart.id,
          items: items,
          total_cents: cart.total_cents
        }
      end
    end
  end
end
