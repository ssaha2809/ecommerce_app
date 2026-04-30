module Api
  module V1
    class ProductsController < BaseController
      before_action :set_product, only: [ :update, :destroy ]

      DEFAULT_PER_PAGE = 25
      MAX_PER_PAGE = 100

      # GET /api/v1/products
      # Query params: category_id, min_price, max_price (cents), q, sort, page, per_page
      def index
        authorize Product

        scope = Product.includes(:category)
          .by_category(params[:category_id])
          .price_between(params[:min_price], params[:max_price])
          .search(params[:q])
          .sorted_by(params[:sort])

        page = params[:page].presence || 1
        per_page = [ (params[:per_page].presence || DEFAULT_PER_PAGE).to_i, MAX_PER_PAGE ].min
        per_page = DEFAULT_PER_PAGE if per_page <= 0

        @products = scope.page(page).per(per_page)

        render json: {
          products: @products.as_json(include: { category: { only: [ :id, :name ] } }),
          meta: {
            current_page: @products.current_page,
            per_page: per_page,
            total_pages: @products.total_pages,
            total_count: @products.total_count
          }
        }, status: :ok
      end

      # GET /api/v1/products/:id
      def show
        product = Product.includes(:category).find(params[:id])
        authorize product
        render json: product.as_json(include: { category: { only: [ :id, :name ] } }), status: :ok
      end

      # POST /api/v1/products
      def create
        @product = Product.new(product_params)
        authorize @product

        if @product.save
          render json: @product.as_json(include: { category: { only: [ :id, :name ] } }), status: :created
        else
          render json: { errors: @product.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # PATCH /api/v1/products/:id
      def update
        authorize @product

        if @product.update(product_params)
          render json: @product.as_json(include: { category: { only: [ :id, :name ] } }), status: :ok
        else
          render json: { errors: @product.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/products/:id
      def destroy
        authorize @product

        if @product.destroy
          head :no_content
        else
          render json: { errors: @product.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def set_product
        @product = Product.find(params[:id])
      end

      def product_params
        params.require(:product).permit(:name, :sku, :description, :price_cents, :stock_quantity, :category_id)
      end
    end
  end
end
