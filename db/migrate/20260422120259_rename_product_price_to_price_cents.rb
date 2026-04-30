class RenameProductPriceToPriceCents < ActiveRecord::Migration[8.1]
  def up
    add_column :products, :price_cents, :integer

    execute <<~SQL.squish
      UPDATE products
      SET price_cents = CAST(ROUND(price * 100) AS INTEGER)
      WHERE price IS NOT NULL
    SQL

    change_column_null :products, :price_cents, false
    remove_column :products, :price
    add_index :products, :price_cents
  end

  def down
    add_column :products, :price, :decimal, precision: 10, scale: 2

    execute <<~SQL.squish
      UPDATE products
      SET price = price_cents / 100.0
      WHERE price_cents IS NOT NULL
    SQL

    change_column_null :products, :price, false
    remove_index :products, :price_cents
    remove_column :products, :price_cents
  end
end
