require "test_helper"

module Api
  module V1
    class CategoriesControllerTest < ActionDispatch::IntegrationTest
      setup do
        @category1 = Category.create!(name: "Electronics", description: "Electronic devices")
        @category2 = Category.create!(name: "Books", description: "Reading materials")

        # Create products for category1
        3.times do |i|
          Product.create!(
            name: "Product #{i}",
            price: 50.0,
            stock_quantity: 10,
            category: @category1
          )
        end

        # Create 1 product for category2
        Product.create!(
          name: "Book Product",
          price: 20.0,
          stock_quantity: 5,
          category: @category2
        )
      end

      test "should get index" do
        get api_v1_categories_url, as: :json
        assert_response :success
        json_response = JSON.parse(response.body)
        assert_equal 2, json_response.size
      end

      test "should include product count in response" do
        get api_v1_categories_url, as: :json
        assert_response :success
        json_response = JSON.parse(response.body)

        electronics_category = json_response.find { |c| c["name"] == "Electronics" }
        books_category = json_response.find { |c| c["name"] == "Books" }

        assert_not_nil electronics_category
        assert_not_nil books_category
        assert_equal 3, electronics_category["products_count"]
        assert_equal 1, books_category["products_count"]
      end

      test "should handle categories with no products" do
        empty_category = Category.create!(name: "Empty Category", description: "No products")

        get api_v1_categories_url, as: :json
        assert_response :success
        json_response = JSON.parse(response.body)

        empty_cat = json_response.find { |c| c["name"] == "Empty Category" }
        assert_not_nil empty_cat
        assert_equal 0, empty_cat["products_count"]
      end

      test "should not have N+1 queries" do
        # Create more categories to test N+1
        5.times do |i|
          category = Category.create!(name: "Category #{i}", description: "Test")
          Product.create!(name: "Product for #{i}", price: 30.0, stock_quantity: 5, category: category)
        end

        # Should only use 1 query with left_joins and group
        assert_queries_count(1) do
          get api_v1_categories_url, as: :json
        end
        assert_response :success
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
