require "test_helper"

class ProductsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @product = create(:product)
  end

  test "should get index" do
    get products_url
    assert_response :success
  end

  test "should get new" do
    get new_product_url
    assert_response :success
  end

  test "should create product" do
    category = create(:category)
    assert_difference("Product.count") do
      post products_url, params: {
        product: {
          name: "Brand New",
          sku: "SKU-WEB-NEW",
          description: "via web form",
          price: 19.99,
          stock_quantity: 5,
          category_id: category.id
        }
      }
    end
    assert_redirected_to product_url(Product.last)
  end

  test "should show product" do
    get product_url(@product)
    assert_response :success
  end

  test "should get edit" do
    get edit_product_url(@product)
    assert_response :success
  end

  test "should update product" do
    patch product_url(@product), params: {
      product: {
        name: "Renamed",
        sku: @product.sku,
        description: @product.description,
        price: @product.price,
        stock_quantity: @product.stock_quantity,
        category_id: @product.category_id
      }
    }
    assert_redirected_to product_url(@product)
  end

  test "should destroy product" do
    assert_difference("Product.count", -1) do
      delete product_url(@product)
    end

    assert_redirected_to products_url
  end
end
