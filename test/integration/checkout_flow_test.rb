require "test_helper"

class CheckoutFlowTest < ActionDispatch::IntegrationTest
  test "complete purchase flow" do
    user     = create(:user)
    category = create(:category)
    product  = create(:product, category: category, price_cents: 1_500, stock_quantity: 10)
    headers  = auth_headers(user)

    # Browse products
    get api_v1_products_url, headers: headers, as: :json
    assert_response :ok
    listed = response.parsed_body["products"].map { |p| p["id"] }
    assert_includes listed, product.id

    # Add to cart
    post api_v1_cart_items_url,
      headers: headers,
      params: { product_id: product.id, quantity: 2 },
      as: :json
    assert_response :created

    # Inspect cart
    get api_v1_cart_url, headers: headers, as: :json
    assert_response :ok
    cart_body = response.parsed_body
    assert_equal 3_000, cart_body["total_cents"]
    assert_equal 1, cart_body["items"].size

    # Checkout
    post api_v1_orders_url, headers: headers, as: :json
    assert_response :created
    order_body = response.parsed_body
    assert_equal "pending", order_body["status"]
    assert_equal 1, order_body["items"].size
    assert_equal 3_000, order_body["total_cents"]

    # Cart should now be empty
    get api_v1_cart_url, headers: headers, as: :json
    assert_equal 0, response.parsed_body["total_cents"]
    assert_empty response.parsed_body["items"]

    # Stock decremented
    assert_equal 8, product.reload.stock_quantity
  end

  test "two customers cannot both grab the last unit" do
    alice    = create(:user)
    bob      = create(:user)
    category = create(:category)
    product  = create(:product, category: category, price_cents: 500, stock_quantity: 1)

    # Both add to their own carts (each sees stock=1 at this point)
    AddToCartService.new(user: alice, product_id: product.id, quantity: 1).call
    AddToCartService.new(user: bob,   product_id: product.id, quantity: 1).call

    # Alice checks out first
    post api_v1_orders_url, headers: auth_headers(alice), as: :json
    assert_response :created
    assert_equal 0, product.reload.stock_quantity

    # Bob's checkout must fail — only one can win the race
    post api_v1_orders_url, headers: auth_headers(bob), as: :json
    assert_response :unprocessable_entity
    assert_match(/insufficient/i, response.parsed_body["errors"].first)

    assert_equal 1, Order.where(user: alice).count
    assert_equal 0, Order.where(user: bob).count
  end
end
