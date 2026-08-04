module Api
  module V1
    class OrdersController < BaseController
      before_action :set_order, only: [ :show, :cancel, :update_status ]

      # GET /api/v1/orders
      def index
        authorize Order
        orders = policy_scope(Order).order(created_at: :desc)
        render json: orders.map { |o| serialize_order(o) }, status: :ok
      end

      # GET /api/v1/orders/:id
      def show
        authorize @order
        render json: serialize_order(@order, include_items: true), status: :ok
      end

      # POST /api/v1/orders
      def create
        authorize Order
        order = CheckoutService.new(current_user).call
        render json: serialize_order(order, include_items: true), status: :created
      rescue CheckoutService::EmptyCartError => e
        render json: { errors: [ e.message ] }, status: :unprocessable_entity
      rescue CheckoutService::InsufficientStockError => e
        render json: { errors: [ e.message ] }, status: :unprocessable_entity
      end

      # PATCH /api/v1/orders/:id/cancel
      def cancel
        authorize @order, :cancel?
        CancelOrderService.new(@order).call
        render json: serialize_order(@order, include_items: true), status: :ok
      rescue CancelOrderService::CancelError => e
        render json: { errors: [ e.message ] }, status: :unprocessable_entity
      end

      # PATCH /api/v1/orders/:id/status
      def update_status
        authorize @order, :update_status?
        new_status = params[:status].to_s
        if @order.update(status: new_status)
          render json: serialize_order(@order, include_items: true), status: :ok
        else
          render json: { errors: @order.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def set_order
        @order = Order.find(params[:id])
      end

      def serialize_order(order, include_items: false)
        payload = {
          id: order.id,
          user_id: order.user_id,
          status: order.status,
          total_cents: order.total_cents,
          created_at: order.created_at
        }
        if include_items
          payload[:items] = order.order_items.map do |item|
            {
              id: item.id,
              product_id: item.product_id,
              quantity: item.quantity,
              unit_price_cents: item.unit_price_cents,
              subtotal_cents: item.subtotal_cents
            }
          end
        end
        payload
      end
    end
  end
end
