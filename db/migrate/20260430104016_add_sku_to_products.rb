class AddSkuToProducts < ActiveRecord::Migration[8.1]
  def up
    add_column :products, :sku, :string

    execute <<~SQL.squish
      UPDATE products
      SET sku = 'SKU-' || id
      WHERE sku IS NULL
    SQL

    change_column_null :products, :sku, false
    add_index :products, :sku, unique: true
  end

  def down
    remove_index :products, :sku
    remove_column :products, :sku
  end
end
