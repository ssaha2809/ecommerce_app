require "test_helper"

module Api
  module V1
    class ProductsControllerTest < ActionDispatch::IntegrationTest
      setup do
        @admin    = create(:user, :admin)
        @customer = create(:user)
        @category = create(:category, name: "Test Category")
        @product  = create(:product, name: "Test Product", category: @category)
      end

      test "should get index as customer" do
        get api_v1_products_url, headers: auth_headers(@customer), as: :json
        assert_response :success
        products = response.parsed_body["products"]
        assert_not_empty products
        assert_includes products.map { |p| p["name"] }, @product.name
      end

      test "should show product as customer" do
        get api_v1_product_url(@product), headers: auth_headers(@customer), as: :json
        assert_response :success
        assert_equal @product.name, response.parsed_body["name"]
      end

      test "admin should create product" do
        assert_difference("Product.count") do
          post api_v1_products_url,
            headers: auth_headers(@admin),
            params: {
              product: {
                name: "New Product",
                sku: "SKU-NEW-001",
                description: "New description",
                price_cents: 14_999,
                stock_quantity: 20,
                category_id: @category.id
              }
            },
            as: :json
        end
        assert_response :created
        assert_equal "New Product", response.parsed_body["name"]
      end

      test "customer cannot create product (403)" do
        assert_no_difference("Product.count") do
          post api_v1_products_url,
            headers: auth_headers(@customer),
            params: {
              product: {
                name: "Forbidden",
                sku: "SKU-FORBID",
                price_cents: 1_000,
                stock_quantity: 1,
                category_id: @category.id
              }
            },
            as: :json
        end
        assert_response :forbidden
        assert_equal "You are not authorized to perform this action", response.parsed_body["error"]
      end

      test "admin should not create with invalid params" do
        assert_no_difference("Product.count") do
          post api_v1_products_url,
            headers: auth_headers(@admin),
            params: {
              product: {
                name: "",
                sku: "",
                price_cents: -10,
                category_id: @category.id
              }
            },
            as: :json
        end
        assert_response :unprocessable_entity
        errors = response.parsed_body["errors"]
        assert_includes errors, "Name can't be blank"
        assert_includes errors, "Sku can't be blank"
        assert_includes errors, "Price cents must be greater than 0"
      end

      test "admin update product" do
        patch api_v1_product_url(@product),
          headers: auth_headers(@admin),
          params: { product: { name: "Updated Product", price_cents: 19_999 } },
          as: :json
        assert_response :success
        assert_equal "Updated Product", response.parsed_body["name"]
        assert_equal 19_999, response.parsed_body["price_cents"]
      end

      test "customer cannot update product (403)" do
        patch api_v1_product_url(@product),
          headers: auth_headers(@customer),
          params: { product: { name: "Nope" } },
          as: :json
        assert_response :forbidden
      end

      test "admin destroy product" do
        assert_difference("Product.count", -1) do
          delete api_v1_product_url(@product), headers: auth_headers(@admin), as: :json
        end
        assert_response :no_content
      end

      test "customer cannot destroy product (403)" do
        assert_no_difference("Product.count") do
          delete api_v1_product_url(@product), headers: auth_headers(@customer), as: :json
        end
        assert_response :forbidden
      end

      test "missing token returns 401" do
        get api_v1_products_url, as: :json
        assert_response :unauthorized
        assert_equal "Unauthorized", response.parsed_body["error"]
      end

      test "invalid token returns 401" do
        get api_v1_products_url,
          headers: { "Authorization" => "Bearer not-a-real-token" },
          as: :json
        assert_response :unauthorized
      end

      test "should return 404 for non-existent product" do
        get api_v1_product_url(id: 99_999), headers: auth_headers(@customer), as: :json
        assert_response :not_found
        assert_equal "Product not found", response.parsed_body["error"]
      end
    end
  end
end
