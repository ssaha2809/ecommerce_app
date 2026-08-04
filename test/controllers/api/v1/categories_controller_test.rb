require "test_helper"

module Api
  module V1
    class CategoriesControllerTest < ActionDispatch::IntegrationTest
      setup do
        @customer  = create(:user)
        @category1 = create(:category, name: "Electronics")
        @category2 = create(:category, name: "Books")

        create_list(:product, 3, category: @category1)
        create(:product, category: @category2)
      end

      test "should get index" do
        get api_v1_categories_url, headers: auth_headers(@customer), as: :json
        assert_response :success
        assert_equal 2, response.parsed_body.size
      end

      test "should include product count in response" do
        get api_v1_categories_url, headers: auth_headers(@customer), as: :json
        assert_response :success

        electronics_category = response.parsed_body.find { |c| c["name"] == "Electronics" }
        books_category       = response.parsed_body.find { |c| c["name"] == "Books" }

        assert_not_nil electronics_category
        assert_not_nil books_category
        assert_equal 3, electronics_category["products_count"]
        assert_equal 1, books_category["products_count"]
      end

      test "should handle categories with no products" do
        empty_category = create(:category, name: "Empty Category")

        get api_v1_categories_url, headers: auth_headers(@customer), as: :json
        assert_response :success

        empty_cat = response.parsed_body.find { |c| c["name"] == empty_category.name }
        assert_not_nil empty_cat
        assert_equal 0, empty_cat["products_count"]
      end

      test "missing token returns 401" do
        get api_v1_categories_url, as: :json
        assert_response :unauthorized
      end
    end
  end
end
