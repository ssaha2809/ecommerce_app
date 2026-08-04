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

      test "index includes category name for each product" do
        get api_v1_products_url, headers: auth_headers(@customer), as: :json
        assert_response :success
        product_json = response.parsed_body["products"].find { |p| p["id"] == @product.id }
        assert_equal @category.name, product_json.dig("category", "name")
      end

      test "index filters by category_id" do
        other_category = create(:category, name: "Other Category")
        create(:product, name: "Other Product", category: other_category)

        get api_v1_products_url,
          headers: auth_headers(@customer),
          params: { category_id: @category.id },
          as: :json
        assert_response :success
        products = response.parsed_body["products"]
        assert_equal [ @category.id ], products.map { |p| p["category_id"] }.uniq
      end

      test "index filters by name (q)" do
        create(:product, name: "Bluetooth Speaker", category: @category)
        create(:product, name: "Wireless Mouse", category: @category)

        get api_v1_products_url,
          headers: auth_headers(@customer),
          params: { q: "bluetooth" },
          as: :json
        assert_response :success
        names = response.parsed_body["products"].map { |p| p["name"] }
        assert_equal [ "Bluetooth Speaker" ], names
      end

      test "index filters by price range" do
        create(:product, name: "Cheap",  price_cents: 200,    category: @category)
        create(:product, name: "Mid",    price_cents: 5_000,  category: @category)
        create(:product, name: "Pricey", price_cents: 50_000, category: @category)

        get api_v1_products_url,
          headers: auth_headers(@customer),
          params: { min_price: 4_000, max_price: 10_000 },
          as: :json
        assert_response :success
        names = response.parsed_body["products"].map { |p| p["name"] }
        assert_equal [ "Mid" ], names
      end

      test "index sorts by price_asc" do
        create(:product, name: "B-Pricey", price_cents: 50_000, category: @category)
        create(:product, name: "A-Cheap",  price_cents: 100,    category: @category)

        get api_v1_products_url,
          headers: auth_headers(@customer),
          params: { sort: "price_asc" },
          as: :json
        assert_response :success
        prices = response.parsed_body["products"].map { |p| p["price_cents"] }
        assert_equal prices.sort, prices
      end

      test "index paginates and returns meta" do
        create_list(:product, 5, category: @category)

        get api_v1_products_url,
          headers: auth_headers(@customer),
          params: { page: 2, per_page: 2 },
          as: :json
        assert_response :success
        body = response.parsed_body
        assert_equal 2, body["products"].size
        assert_equal 2, body.dig("meta", "current_page")
        assert_equal 2, body.dig("meta", "per_page")
        assert_equal 6, body.dig("meta", "total_count")
        assert_equal 3, body.dig("meta", "total_pages")
      end

      test "index treats invalid page param as page 1" do
        get api_v1_products_url,
          headers: auth_headers(@customer),
          params: { page: "-3" },
          as: :json
        assert_response :success
        assert_equal 1, response.parsed_body.dig("meta", "current_page")
      end

      test "index combines filter and sort" do
        create(:product, name: "Filter-A", price_cents: 800,  category: @category)
        create(:product, name: "Filter-B", price_cents: 200,  category: @category)
        other_category = create(:category, name: "Excluded")
        create(:product, name: "Excluded", price_cents: 100, category: other_category)

        get api_v1_products_url,
          headers: auth_headers(@customer),
          params: { category_id: @category.id, q: "Filter-", sort: "price_asc" },
          as: :json
        assert_response :success
        names = response.parsed_body["products"].map { |p| p["name"] }
        assert_equal [ "Filter-B", "Filter-A" ], names
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

      test "create ignores unpermitted parameters" do
        post api_v1_products_url,
          headers: auth_headers(@admin),
          params: {
            product: {
              name: "Strong Params Test",
              sku: "SKU-STRONG-001",
              price_cents: 1_500,
              stock_quantity: 5,
              category_id: @category.id,
              admin_notes: "should be ignored",
              id: 999_999
            }
          },
          as: :json
        assert_response :created
        body = response.parsed_body
        assert_not_equal 999_999, body["id"]
        assert_nil body["admin_notes"]
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
