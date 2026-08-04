class OverhaulOrderItemsForFeature6 < ActiveRecord::Migration[8.1]
  def up
    # Any legacy rows were already cleared in the orders migration.
    add_column :order_items, :unit_price_cents, :integer, null: false, default: 0
    change_column_default :order_items, :unit_price_cents, nil

    # Replace the legacy decimal column with the cents snapshot column.
    remove_column :order_items, :unit_price, :decimal, precision: 10, scale: 2

    change_column_default :order_items, :quantity, nil
  end

  def down
    change_column_default :order_items, :quantity, 1
    add_column :order_items, :unit_price, :decimal, precision: 10, scale: 2, null: false
    remove_column :order_items, :unit_price_cents
  end
end
