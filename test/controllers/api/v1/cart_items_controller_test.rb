require "test_helper"

module Api
  module V1
    class CartItemsControllerTest < ActionDispatch::IntegrationTest
      setup do
        @user     = create(:user)
        @category = create(:category)
        @product  = create(:product, category: @category, price_cents: 1_000, stock_quantity: 5)
      end

      test "POST creates a cart item and the cart when needed" do
        assert_difference("Cart.count", 1) do
          assert_difference("CartItem.count", 1) do
            post api_v1_cart_items_url,
              headers: auth_headers(@user),
              params: { product_id: @product.id, quantity: 2 },
              as: :json
          end
        end
        assert_response :created
        body = response.parsed_body
        assert_equal 2, body["quantity"]
        assert_equal 2_000, body["subtotal_cents"]
      end

      test "POST returns 422 when stock insufficient" do
        post api_v1_cart_items_url,
          headers: auth_headers(@user),
          params: { product_id: @product.id, quantity: 99 },
          as: :json
        assert_response :unprocessable_entity
        assert_match(/available/i, response.parsed_body["errors"].first)
      end

      test "POST returns 404 for unknown product" do
        post api_v1_cart_items_url,
          headers: auth_headers(@user),
          params: { product_id: 99_999, quantity: 1 },
          as: :json
        assert_response :not_found
      end

      test "POST returns 401 without auth" do
        post api_v1_cart_items_url,
          params: { product_id: @product.id, quantity: 1 },
          as: :json
        assert_response :unauthorized
      end

      test "PATCH updates the cart item quantity" do
        cart = create(:cart, user: @user)
        item = create(:cart_item, cart: cart, product: @product, quantity: 1)

        patch api_v1_cart_item_url(item),
          headers: auth_headers(@user),
          params: { quantity: 3 },
          as: :json

        assert_response :ok
        assert_equal 3, item.reload.quantity
      end

      test "PATCH rejects update exceeding stock" do
        cart = create(:cart, user: @user)
        item = create(:cart_item, cart: cart, product: @product, quantity: 1)

        patch api_v1_cart_item_url(item),
          headers: auth_headers(@user),
          params: { quantity: 99 },
          as: :json

        assert_response :unprocessable_entity
        assert_equal 1, item.reload.quantity
      end

      test "PATCH forbidden for non-owner" do
        cart = create(:cart, user: @user)
        item = create(:cart_item, cart: cart, product: @product, quantity: 1)
        intruder = create(:user)

        patch api_v1_cart_item_url(item),
          headers: auth_headers(intruder),
          params: { quantity: 2 },
          as: :json

        assert_response :forbidden
      end

      test "DELETE removes the cart item" do
        cart = create(:cart, user: @user)
        item = create(:cart_item, cart: cart, product: @product, quantity: 1)

        assert_difference("CartItem.count", -1) do
          delete api_v1_cart_item_url(item), headers: auth_headers(@user), as: :json
        end
        assert_response :no_content
      end

      test "DELETE forbidden for non-owner" do
        cart = create(:cart, user: @user)
        item = create(:cart_item, cart: cart, product: @product, quantity: 1)
        intruder = create(:user)

        assert_no_difference("CartItem.count") do
          delete api_v1_cart_item_url(item), headers: auth_headers(intruder), as: :json
        end
        assert_response :forbidden
      end
    end

    class CartsControllerTest < ActionDispatch::IntegrationTest
      setup do
        @user     = create(:user)
        @category = create(:category)
        @product  = create(:product, category: @category, price_cents: 1_000, stock_quantity: 5)
      end

      test "GET cart returns items and total" do
        cart = create(:cart, user: @user)
        create(:cart_item, cart: cart, product: @product, quantity: 2)

        get api_v1_cart_url, headers: auth_headers(@user), as: :json

        assert_response :ok
        body = response.parsed_body
        assert_equal 2_000, body["total_cents"]
        assert_equal 1, body["items"].size
        assert_equal @product.id, body["items"].first["product_id"]
      end

      test "GET cart creates an empty cart if user has none" do
        assert_difference("Cart.count", 1) do
          get api_v1_cart_url, headers: auth_headers(@user), as: :json
        end
        assert_response :ok
        body = response.parsed_body
        assert_equal 0, body["total_cents"]
        assert_equal [], body["items"]
      end

      test "carts belong to individual users" do
        other = create(:user)
        my_cart    = create(:cart, user: @user)
        other_cart = create(:cart, user: other)
        create(:cart_item, cart: other_cart, product: @product, quantity: 1)

        get api_v1_cart_url, headers: auth_headers(@user), as: :json
        body = response.parsed_body
        assert_equal my_cart.id, body["id"]
        assert_empty body["items"]
      end
    end
  end
end
