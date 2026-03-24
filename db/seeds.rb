# Clear existing data
OrderItem.destroy_all
Order.destroy_all
Product.destroy_all

# Create Products
puts "Creating products..."

products = [
  {
    name: "Laptop Computer",
    description: "High-performance laptop with 16GB RAM and 512GB SSD",
    price: 1299.99,
    stock_quantity: 15
  },
  {
    name: "Wireless Mouse",
    description: "Ergonomic wireless mouse with precision tracking",
    price: 29.99,
    stock_quantity: 50
  },
  {
    name: "Mechanical Keyboard",
    description: "RGB mechanical keyboard with Cherry MX switches",
    price: 149.99,
    stock_quantity: 30
  },
  {
    name: "USB-C Hub",
    description: "7-in-1 USB-C hub with HDMI, USB 3.0, and card readers",
    price: 49.99,
    stock_quantity: 40
  },
  {
    name: "Wireless Headphones",
    description: "Noise-cancelling wireless headphones with 30-hour battery",
    price: 199.99,
    stock_quantity: 25
  },
  {
    name: "4K Monitor",
    description: "27-inch 4K UHD monitor with IPS panel",
    price: 399.99,
    stock_quantity: 20
  },
  {
    name: "Webcam HD",
    description: "1080p HD webcam with auto-focus and built-in microphone",
    price: 79.99,
    stock_quantity: 35
  },
  {
    name: "External SSD 1TB",
    description: "Portable external SSD with 1TB storage and USB 3.1",
    price: 129.99,
    stock_quantity: 45
  }
]

products.each do |product_data|
  Product.create!(product_data)
end

puts "Created #{Product.count} products"

# Create Orders
puts "Creating orders..."

# Order 1
order1 = Order.create!(
  customer_name: "John Smith",
  customer_email: "john.smith@example.com",
  customer_address: "123 Main St, Springfield, IL 62701",
  status: "completed"
)

OrderItem.create!(
  order: order1,
  product: Product.find_by(name: "Laptop Computer"),
  quantity: 1,
  unit_price: Product.find_by(name: "Laptop Computer").price
)

OrderItem.create!(
  order: order1,
  product: Product.find_by(name: "Wireless Mouse"),
  quantity: 2,
  unit_price: Product.find_by(name: "Wireless Mouse").price
)

order1.save!

# Order 2
order2 = Order.create!(
  customer_name: "Jane Doe",
  customer_email: "jane.doe@example.com",
  customer_address: "456 Oak Ave, Portland, OR 97201",
  status: "processing"
)

OrderItem.create!(
  order: order2,
  product: Product.find_by(name: "4K Monitor"),
  quantity: 2,
  unit_price: Product.find_by(name: "4K Monitor").price
)

OrderItem.create!(
  order: order2,
  product: Product.find_by(name: "Mechanical Keyboard"),
  quantity: 1,
  unit_price: Product.find_by(name: "Mechanical Keyboard").price
)

OrderItem.create!(
  order: order2,
  product: Product.find_by(name: "Wireless Mouse"),
  quantity: 1,
  unit_price: Product.find_by(name: "Wireless Mouse").price
)

order2.save!

# Order 3
order3 = Order.create!(
  customer_name: "Bob Johnson",
  customer_email: "bob.johnson@example.com",
  customer_address: "789 Pine Rd, Austin, TX 78701",
  status: "pending"
)

OrderItem.create!(
  order: order3,
  product: Product.find_by(name: "Wireless Headphones"),
  quantity: 1,
  unit_price: Product.find_by(name: "Wireless Headphones").price
)

OrderItem.create!(
  order: order3,
  product: Product.find_by(name: "External SSD 1TB"),
  quantity: 1,
  unit_price: Product.find_by(name: "External SSD 1TB").price
)

order3.save!

puts "Created #{Order.count} orders with #{OrderItem.count} order items"
puts "Seed data created successfully!"
