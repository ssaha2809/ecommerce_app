# E-Commerce Rails Application

A full-featured e-commerce application built with Ruby on Rails 8.1.2, featuring complete CRUD operations for Products and Orders with a many-to-many relationship through OrderItems.

## Features

- **Product Management**: Full CRUD operations for products with name, description, price, and stock quantity
- **Order Management**: Complete order system with customer information and multiple products per order
- **Order Items**: Join table linking orders and products with quantity and unit price tracking
- **Bootstrap UI**: Modern, responsive interface using Bootstrap 5.3
- **Auto-calculated Totals**: Order totals automatically calculated based on order items
- **Status Tracking**: Order status management (pending, processing, completed, cancelled)

## Technology Stack

- **Ruby**: 3.4.8
- **Rails**: 8.1.2
- **Database**: SQLite3
- **Frontend**: Bootstrap 5.3, Turbo, Stimulus
- **CSS**: Dart Sass

## Getting Started

### Prerequisites

- Ruby 3.4.8 or higher
- Rails 8.1.2 or higher
- SQLite3

### Installation

1. Clone the repository or navigate to the project directory:
   ```bash
   cd /Users/sumanasaha/intellij-workspace/ecommerce_app
   ```

2. Install dependencies:
   ```bash
   bundle install
   ```

3. Set up the database:
   ```bash
   rails db:migrate
   rails db:seed
   ```

4. Start the server:
   ```bash
   bin/dev
   ```

   Or if you prefer to run without the asset compilation watcher:
   ```bash
   rails server
   ```

5. Visit the application at `http://localhost:3000`

## Database Schema

### Products
- `name` (string, required)
- `description` (text)
- `price` (decimal, required)
- `stock_quantity` (integer, default: 0)

### Orders
- `customer_name` (string, required)
- `customer_email` (string, required, validated)
- `customer_address` (text)
- `total_amount` (decimal, auto-calculated)
- `status` (string, default: 'pending')

### OrderItems (Join Table)
- `order_id` (foreign key)
- `product_id` (foreign key)
- `quantity` (integer, required)
- `unit_price` (decimal, required) - captures price at time of order

## Usage

### Managing Products

1. Navigate to the Products page from the main navigation
2. Click "New Product" to create a product
3. Fill in the product details (name, description, price, stock quantity)
4. Click "Create Product" to save

### Creating Orders

1. Navigate to the Orders page from the main navigation
2. Click "New Order" to create an order
3. Fill in customer information
4. Click "Add Product" to add items to the order
5. Select products and quantities
6. The total is automatically calculated
7. Click "Create Order" to save

### Viewing Orders

- Orders list shows all orders with customer details, total, and status
- Click "Show" to view full order details including all order items
- Order details page displays customer information and itemized list of products

## Sample Data

The application comes with seed data including:
- 8 sample products (laptops, peripherals, accessories)
- 3 sample orders with various products
- Complete order items demonstrating the many-to-many relationship

## Features in Detail

### Product Management
- List all products in a searchable table
- Create new products with validation
- Edit existing products
- Delete products (with restriction if used in orders)
- View detailed product information

### Order Management
- List all orders with status badges
- Create orders with multiple products
- Dynamic product selection with live total calculation
- Edit existing orders (add/remove items)
- Delete orders (cascades to order items)
- View complete order details with itemized breakdown

### User Interface
- Responsive Bootstrap 5 design
- Navigation bar with quick access to Products and Orders
- Alert notifications for CRUD operations
- Confirmation dialogs for destructive actions
- Form validations with error messages

## Testing

Run the test suite:
```bash
rails test
```

## Development

To work on this project:

1. Make your changes
2. Run migrations if you've modified the database:
   ```bash
   rails db:migrate
   ```
3. Test your changes:
   ```bash
   rails test
   ```

## Project Structure

```
app/
├── controllers/
│   ├── products_controller.rb
│   └── orders_controller.rb
├── models/
│   ├── product.rb
│   ├── order.rb
│   └── order_item.rb
├── views/
│   ├── products/
│   └── orders/
└── assets/
    └── stylesheets/
        └── application.scss
```

## License

This project is available for educational purposes.
