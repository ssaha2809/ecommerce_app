module Api
  module V1
    class CartItemsController < BaseController
      before_action :set_cart_item, only: [:update, :destroy]

      # POST /api/v1/cart/items
      def create
        authorize CartItem
        result = AddToCartService.new(
          user: current_user,
          product_id: params[:product_id],
          quantity: params[:quantity]
        ).call

        render json: serialize_item(result.cart_item),
               status: (result.status == :created ? :created : :ok)
      rescue AddToCartService::ProductNotFoundError
        render json: { error: "Product not found" }, status: :not_found
      rescue AddToCartService::InsufficientStockError => e
        render json: { errors: [e.message] }, status: :unprocessable_entity
      end

      # PATCH /api/v1/cart/items/:id
      def update
        authorize @cart_item

        new_quantity = params[:quantity].to_i
        stock_error = nil

        ActiveRecord::Base.transaction do
          product = Product.lock.find(@cart_item.product_id)
          if new_quantity > product.stock_quantity
            stock_error = "Quantity exceeds available stock (#{product.stock_quantity})"
            raise ActiveRecord::Rollback
          end
          @cart_item.update!(quantity: new_quantity)
        end

        if stock_error
          render json: { errors: [stock_error] }, status: :unprocessable_entity
        else
          render json: serialize_item(@cart_item), status: :ok
        end
      end

      # DELETE /api/v1/cart/items/:id
      def destroy
        authorize @cart_item
        @cart_item.destroy!
        head :no_content
      end

      private

      def set_cart_item
        @cart_item = CartItem.find(params[:id])
      end

      def serialize_item(item)
        {
          id: item.id,
          product_id: item.product_id,
          quantity: item.quantity,
          subtotal_cents: item.subtotal_cents
        }
      end
    end
  end
end
