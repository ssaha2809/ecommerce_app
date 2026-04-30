# Idempotent seed: clears catalog and order data, then creates 5 categories,
# 20 products and a few sample orders. Safe to run repeatedly with `rails db:seed`.

OrderItem.destroy_all
Order.destroy_all
Product.destroy_all
Category.destroy_all
User.destroy_all

puts "Creating users..."

User.create!(name: "Admin User",    email: "admin@example.com",    role: :admin,    api_token: "admin-dev-token")
User.create!(name: "Customer User", email: "customer@example.com", role: :customer, api_token: "customer-dev-token")

puts "Created #{User.count} users (api_tokens: 'admin-dev-token', 'customer-dev-token')"

puts "Creating categories..."

categories = {
  electronics:          Category.create!(name: "Electronics",          description: "Electronic devices and accessories"),
  computer_accessories: Category.create!(name: "Computer Accessories", description: "Accessories for computers and laptops"),
  audio:                Category.create!(name: "Audio",                description: "Audio equipment and accessories"),
  storage:              Category.create!(name: "Storage",              description: "Storage devices and solutions"),
  office:               Category.create!(name: "Office",               description: "Office supplies and furniture")
}

puts "Created #{Category.count} categories"

puts "Creating products..."

products = [
  { name: "Laptop Computer",       sku: "ELEC-LAPTOP-001",  description: "High-performance laptop with 16GB RAM and 512GB SSD", price_cents: 129_999, stock_quantity: 15, category: categories[:electronics] },
  { name: "4K Monitor",            sku: "ELEC-MON-4K-001",  description: "27-inch 4K UHD monitor with IPS panel",               price_cents:  39_999, stock_quantity: 20, category: categories[:electronics] },
  { name: "Smartphone",            sku: "ELEC-PHONE-001",   description: "5G smartphone with 128GB storage",                    price_cents:  79_999, stock_quantity: 12, category: categories[:electronics] },
  { name: "Tablet",                sku: "ELEC-TAB-001",     description: "10-inch tablet with stylus support",                  price_cents:  49_999, stock_quantity: 18, category: categories[:electronics] },

  { name: "Wireless Mouse",        sku: "ACC-MOUSE-001",    description: "Ergonomic wireless mouse with precision tracking",    price_cents:   2_999, stock_quantity: 50, category: categories[:computer_accessories] },
  { name: "Mechanical Keyboard",   sku: "ACC-KB-MECH-001",  description: "RGB mechanical keyboard with Cherry MX switches",     price_cents:  14_999, stock_quantity: 30, category: categories[:computer_accessories] },
  { name: "USB-C Hub",             sku: "ACC-HUB-USBC-001", description: "7-in-1 USB-C hub with HDMI, USB 3.0, and card readers", price_cents: 4_999, stock_quantity: 40, category: categories[:computer_accessories] },
  { name: "Webcam HD",             sku: "ACC-WEBCAM-001",   description: "1080p HD webcam with auto-focus and built-in microphone", price_cents: 7_999, stock_quantity: 35, category: categories[:computer_accessories] },
  { name: "Laptop Stand",          sku: "ACC-STAND-001",    description: "Aluminium laptop stand with adjustable angle",        price_cents:   3_999, stock_quantity: 60, category: categories[:computer_accessories] },

  { name: "Wireless Headphones",   sku: "AUD-HP-WL-001",    description: "Noise-cancelling wireless headphones with 30-hour battery", price_cents: 19_999, stock_quantity: 25, category: categories[:audio] },
  { name: "Bluetooth Speaker",     sku: "AUD-SPK-BT-001",   description: "Portable bluetooth speaker with deep bass",           price_cents:   5_999, stock_quantity: 40, category: categories[:audio] },
  { name: "Studio Microphone",     sku: "AUD-MIC-001",      description: "USB studio microphone with cardioid pattern",         price_cents:  12_999, stock_quantity: 18, category: categories[:audio] },
  { name: "In-Ear Monitors",       sku: "AUD-IEM-001",      description: "Triple-driver in-ear monitors",                       price_cents:   8_999, stock_quantity: 22, category: categories[:audio] },

  { name: "External SSD 1TB",      sku: "STO-SSD-1TB-001",  description: "Portable external SSD with 1TB storage and USB 3.1",  price_cents:  12_999, stock_quantity: 45, category: categories[:storage] },
  { name: "External HDD 4TB",      sku: "STO-HDD-4TB-001",  description: "4TB external hard drive for backup",                  price_cents:   9_999, stock_quantity: 30, category: categories[:storage] },
  { name: "USB Flash Drive 128GB", sku: "STO-USB-128-001",  description: "128GB USB 3.2 flash drive",                           price_cents:   1_999, stock_quantity: 80, category: categories[:storage] },
  { name: "NAS Enclosure",         sku: "STO-NAS-001",      description: "Two-bay NAS enclosure for home or small office",      price_cents:  29_999, stock_quantity:  8, category: categories[:storage] },

  { name: "Office Chair",          sku: "OFF-CHAIR-001",    description: "Ergonomic office chair with lumbar support",          price_cents:  24_999, stock_quantity: 10, category: categories[:office] },
  { name: "Standing Desk",         sku: "OFF-DESK-001",     description: "Electric standing desk, 120x60cm",                    price_cents:  39_999, stock_quantity:  6, category: categories[:office] },
  { name: "Desk Lamp",             sku: "OFF-LAMP-001",     description: "LED desk lamp with adjustable colour temperature",    price_cents:   3_499, stock_quantity: 50, category: categories[:office] }
]

products.each { |attrs| Product.create!(attrs) }

puts "Created #{Product.count} products"

puts "Creating orders..."

order1 = Order.create!(
  customer_name: "John Smith",
  customer_email: "john.smith@example.com",
  customer_address: "123 Main St, Springfield, IL 62701",
  status: "completed"
)
OrderItem.create!(order: order1, product: Product.find_by!(sku: "ELEC-LAPTOP-001"), quantity: 1, unit_price: Product.find_by!(sku: "ELEC-LAPTOP-001").price)
OrderItem.create!(order: order1, product: Product.find_by!(sku: "ACC-MOUSE-001"),   quantity: 2, unit_price: Product.find_by!(sku: "ACC-MOUSE-001").price)

order2 = Order.create!(
  customer_name: "Jane Doe",
  customer_email: "jane.doe@example.com",
  customer_address: "456 Oak Ave, Portland, OR 97201",
  status: "processing"
)
OrderItem.create!(order: order2, product: Product.find_by!(sku: "ELEC-MON-4K-001"),  quantity: 2, unit_price: Product.find_by!(sku: "ELEC-MON-4K-001").price)
OrderItem.create!(order: order2, product: Product.find_by!(sku: "ACC-KB-MECH-001"),  quantity: 1, unit_price: Product.find_by!(sku: "ACC-KB-MECH-001").price)

order3 = Order.create!(
  customer_name: "Bob Johnson",
  customer_email: "bob.johnson@example.com",
  customer_address: "789 Pine Rd, Austin, TX 78701",
  status: "pending"
)
OrderItem.create!(order: order3, product: Product.find_by!(sku: "AUD-HP-WL-001"),    quantity: 1, unit_price: Product.find_by!(sku: "AUD-HP-WL-001").price)
OrderItem.create!(order: order3, product: Product.find_by!(sku: "STO-SSD-1TB-001"),  quantity: 1, unit_price: Product.find_by!(sku: "STO-SSD-1TB-001").price)

puts "Created #{Order.count} orders with #{OrderItem.count} order items"
puts "Seed data created successfully!"
