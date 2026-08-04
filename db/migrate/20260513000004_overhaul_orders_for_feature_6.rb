class OverhaulOrdersForFeature6 < ActiveRecord::Migration[8.1]
  def up
    # Discard any legacy dev/test order rows so we can tighten constraints.
    # Safe here because there is no real data — this is a learning repo.
    execute "DELETE FROM order_items"
    execute "DELETE FROM orders"

    add_reference :orders, :user, foreign_key: true
    change_column_null :orders, :user_id, false

    add_column :orders, :total_cents, :integer, null: false, default: 0

    # customer_* fields become optional snapshot info populated from User at checkout.
    change_column_null :orders, :customer_name,  true
    change_column_null :orders, :customer_email, true

    # Legacy decimal total_amount is replaced by total_cents.
    remove_column :orders, :total_amount, :decimal, precision: 10, scale: 2, default: "0.0"

    # Index for the common "list this user's orders" query.
    add_index :orders, [ :user_id, :created_at ]
  end

  def down
    remove_index  :orders, [ :user_id, :created_at ]
    add_column    :orders, :total_amount, :decimal, precision: 10, scale: 2, default: "0.0"
    change_column_null :orders, :customer_email, false
    change_column_null :orders, :customer_name,  false
    remove_column :orders, :total_cents
    remove_reference :orders, :user, foreign_key: true
  end
end
