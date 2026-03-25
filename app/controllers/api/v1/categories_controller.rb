module Api
  module V1
    class CategoriesController < BaseController
      # GET /api/v1/categories
      def index
        @categories = Category.left_joins(:products)
                              .select("categories.*, COUNT(products.id) as products_count")
                              .group("categories.id")

        categories_with_count = @categories.map do |category|
          {
            id: category.id,
            name: category.name,
            description: category.description,
            created_at: category.created_at,
            updated_at: category.updated_at,
            products_count: category.products_count
          }
        end

        render json: categories_with_count, status: :ok
      end
    end
  end
end
