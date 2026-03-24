json.extract! order, :id, :customer_name, :customer_email, :customer_address, :total_amount, :status, :created_at, :updated_at
json.url order_url(order, format: :json)
