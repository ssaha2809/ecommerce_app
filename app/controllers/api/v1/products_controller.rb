module Api
  module V1
    class ProductsController < BaseController
      before_action :set_product, only: [ :show, :update, :destroy ]

      # GET /api/v1/products
      def index
        @products = Product.includes(:category).all
        render json: @products.as_json(include: { category: { only: [ :id, :name ] } }), status: :ok
      end

      # GET /api/v1/products/:id
      def show
        render json: @product.as_json(include: { category: { only: [ :id, :name ] } }), status: :ok
      end

      # POST /api/v1/products
      def create
        @product = Product.new(product_params)

        if @product.save
          render json: @product.as_json(include: { category: { only: [ :id, :name ] } }), status: :created
        else
          render json: { errors: @product.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/products/:id
      def update
        if @product.update(product_params)
          render json: @product.as_json(include: { category: { only: [ :id, :name ] } }), status: :ok
        else
          render json: { errors: @product.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/products/:id
      def destroy
        if @product.destroy
          head :no_content
        else
          render json: { errors: @product.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def set_product
        # Only eager load category for show action, not for update/destroy
        if action_name == "show"
          @product = Product.includes(:category).find_by(id: params[:id])
        else
          @product = Product.find_by(id: params[:id])
        end
        render json: { error: "Product not found" }, status: :not_found unless @product
      end

      def product_params
        params.require(:product).permit(:name, :description, :price, :stock_quantity, :category_id)
      end
    end
  end
end
