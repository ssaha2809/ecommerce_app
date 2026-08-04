require "test_helper"

module Api
  module V1
    class OrdersControllerTest < ActionDispatch::IntegrationTest
      setup do
        @customer = create(:user)
        @other    = create(:user)
        @admin    = create(:user, :admin)
        @category = create(:category)
        @product  = create(:product, category: @category, price_cents: 1_000, stock_quantity: 5)
      end

      def add_to_cart(user, product, quantity)
        AddToCartService.new(user: user, product_id: product.id, quantity: quantity).call
      end

      test "POST creates an order from the user's cart" do
        add_to_cart(@customer, @product, 2)

        assert_difference("Order.count", 1) do
          post api_v1_orders_url, headers: auth_headers(@customer), as: :json
        end
        assert_response :created
        body = response.parsed_body
        assert_equal "pending", body["status"]
        assert_equal 2_000, body["total_cents"]
        assert_equal 1, body["items"].size
      end

      test "POST returns 422 for empty cart" do
        post api_v1_orders_url, headers: auth_headers(@customer), as: :json
        assert_response :unprocessable_entity
        assert_match(/empty/i, response.parsed_body["errors"].first)
      end

      test "POST rolls back when stock vanishes between cart and checkout" do
        add_to_cart(@customer, @product, 3)
        @product.update!(stock_quantity: 1)

        assert_no_difference("Order.count") do
          post api_v1_orders_url, headers: auth_headers(@customer), as: :json
        end
        assert_response :unprocessable_entity
        assert_equal 1, @product.reload.stock_quantity
      end

      test "GET index returns only customer's own orders" do
        my_order    = create(:order, user: @customer)
        _other_order = create(:order, user: @other)

        get api_v1_orders_url, headers: auth_headers(@customer), as: :json
        assert_response :ok
        ids = response.parsed_body.map { |o| o["id"] }
        assert_equal [ my_order.id ], ids
      end

      test "GET index as admin returns all orders" do
        my_order    = create(:order, user: @customer)
        other_order = create(:order, user: @other)

        get api_v1_orders_url, headers: auth_headers(@admin), as: :json
        assert_response :ok
        ids = response.parsed_body.map { |o| o["id"] }
        assert_includes ids, my_order.id
        assert_includes ids, other_order.id
      end

      test "GET show as owner" do
        order = create(:order, user: @customer)
        get api_v1_order_url(order), headers: auth_headers(@customer), as: :json
        assert_response :ok
      end

      test "GET show as other customer returns 403" do
        order = create(:order, user: @customer)
        get api_v1_order_url(order), headers: auth_headers(@other), as: :json
        assert_response :forbidden
      end

      test "GET show as admin allowed" do
        order = create(:order, user: @customer)
        get api_v1_order_url(order), headers: auth_headers(@admin), as: :json
        assert_response :ok
      end

      test "PATCH cancel restores stock for owner" do
        add_to_cart(@customer, @product, 2)
        post api_v1_orders_url, headers: auth_headers(@customer), as: :json
        order_id = response.parsed_body["id"]
        assert_equal 3, @product.reload.stock_quantity

        patch cancel_api_v1_order_url(order_id), headers: auth_headers(@customer), as: :json
        assert_response :ok
        assert_equal "cancelled", response.parsed_body["status"]
        assert_equal 5, @product.reload.stock_quantity
      end

      test "PATCH cancel forbidden for non-owner" do
        order = create(:order, user: @customer)
        patch cancel_api_v1_order_url(order), headers: auth_headers(@other), as: :json
        assert_response :forbidden
      end

      test "PATCH cancel forbidden once shipped" do
        order = create(:order, user: @customer)
        order.update!(status: "confirmed")
        order.update!(status: "shipped")
        patch cancel_api_v1_order_url(order), headers: auth_headers(@customer), as: :json
        assert_response :forbidden
      end

      test "PATCH status as admin transitions order" do
        order = create(:order, user: @customer)
        patch status_api_v1_order_url(order),
          headers: auth_headers(@admin), params: { status: "confirmed" }, as: :json
        assert_response :ok
        assert_equal "confirmed", response.parsed_body["status"]
      end

      test "PATCH status as customer forbidden" do
        order = create(:order, user: @customer)
        patch status_api_v1_order_url(order),
          headers: auth_headers(@customer), params: { status: "confirmed" }, as: :json
        assert_response :forbidden
      end

      test "PATCH status rejects invalid transition with 422" do
        order = create(:order, user: @customer)
        patch status_api_v1_order_url(order),
          headers: auth_headers(@admin), params: { status: "delivered" }, as: :json
        assert_response :unprocessable_entity
      end
    end
  end
end
