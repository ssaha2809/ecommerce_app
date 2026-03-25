require "test_helper"

module Api
  module V1
    class ProductsControllerTest < ActionDispatch::IntegrationTest
      setup do
        @category = Category.create!(name: "Test Category", description: "Test description")
        @product = Product.create!(
          name: "Test Product",
          description: "Test description",
          price: 99.99,
          stock_quantity: 10,
          category: @category
        )
      end

      test "should get index" do
        get api_v1_products_url, as: :json
        assert_response :success
        json_response = JSON.parse(response.body)
        assert_not_empty json_response
        assert_equal @product.name, json_response.first["name"]
        assert_not_nil json_response.first["category"]
        assert_equal @category.name, json_response.first["category"]["name"]
      end

      test "should get index without N+1 queries" do
        # Create additional products to test N+1
        5.times do |i|
          Product.create!(
            name: "Product #{i}",
            price: 50.0,
            stock_quantity: 5,
            category: @category
          )
        end

        # This should only generate 2 queries (products + categories)
        assert_queries_count(2) do
          get api_v1_products_url, as: :json
        end
        assert_response :success
      end

      test "should show product" do
        get api_v1_product_url(@product), as: :json
        assert_response :success
        json_response = JSON.parse(response.body)
        assert_equal @product.name, json_response["name"]
        assert_not_nil json_response["category"]
        assert_equal @category.name, json_response["category"]["name"]
      end

      test "should create product" do
        assert_difference("Product.count") do
          post api_v1_products_url, params: {
            product: {
              name: "New Product",
              description: "New description",
              price: 149.99,
              stock_quantity: 20,
              category_id: @category.id
            }
          }, as: :json
        end
        assert_response :created
        json_response = JSON.parse(response.body)
        assert_equal "New Product", json_response["name"]
      end

      test "should not create product with invalid params" do
        assert_no_difference("Product.count") do
          post api_v1_products_url, params: {
            product: {
              name: "",
              price: -10
            }
          }, as: :json
        end
        assert_response :unprocessable_entity
        json_response = JSON.parse(response.body)
        assert_not_empty json_response["errors"]
      end

      test "should reject unexpected fields with strong parameters" do
        post api_v1_products_url, params: {
          product: {
            name: "Hack Product",
            price: 50.0,
            stock_quantity: 10,
            admin: true, # This should be filtered out
            created_at: "2020-01-01" # This should be filtered out
          }
        }, as: :json

        # Should succeed but ignore the unpermitted params
        assert_response :created
        product = Product.last
        # Verify the unpermitted attributes were not set
        assert_not_equal "2020-01-01", product.created_at.to_s
      end

      test "should update product" do
        patch api_v1_product_url(@product), params: {
          product: {
            name: "Updated Product",
            price: 199.99
          }
        }, as: :json
        assert_response :success
        json_response = JSON.parse(response.body)
        assert_equal "Updated Product", json_response["name"]
        assert_equal "199.99", json_response["price"]
      end

      test "should not update product with invalid params" do
        patch api_v1_product_url(@product), params: {
          product: {
            name: "",
            price: -50
          }
        }, as: :json
        assert_response :unprocessable_entity
        json_response = JSON.parse(response.body)
        assert_not_empty json_response["errors"]
      end

      test "should destroy product" do
        assert_difference("Product.count", -1) do
          delete api_v1_product_url(@product), as: :json
        end
        assert_response :no_content
      end

      test "should return 404 for non-existent product" do
        get api_v1_product_url(id: 99999), as: :json
        assert_response :not_found
        json_response = JSON.parse(response.body)
        assert_equal "Product not found", json_response["error"]
      end

      test "should return 404 when updating non-existent product" do
        patch api_v1_product_url(id: 99999), params: {
          product: { name: "Test" }
        }, as: :json
        assert_response :not_found
      end

      test "should return 404 when deleting non-existent product" do
        delete api_v1_product_url(id: 99999), as: :json
        assert_response :not_found
      end

      private

      def assert_queries_count(expected_count)
        queries = []
        subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |_, _, _, _, payload|
          queries << payload[:sql] unless payload[:name] == "SCHEMA"
        end

        yield

        ActiveSupport::Notifications.unsubscribe(subscriber)
        assert_equal expected_count, queries.size, "Expected #{expected_count} queries, got #{queries.size}:\n#{queries.join("\n")}"
      end
    end
  end
end
