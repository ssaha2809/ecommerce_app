class TightenCatalogNullConstraints < ActiveRecord::Migration[8.1]
  def up
    # Backfill any NULLs before tightening constraints.
    execute "UPDATE categories SET name = 'Uncategorized-' || id WHERE name IS NULL"
    execute "UPDATE products SET stock_quantity = 0 WHERE stock_quantity IS NULL"

    change_column_null :categories, :name, false
    change_column_null :products, :stock_quantity, false

    # category_id is the application-required association. Backfill orphans
    # to a sentinel category so we can enforce NOT NULL.
    if execute_count("SELECT COUNT(*) FROM products WHERE category_id IS NULL").positive?
      sentinel_id = ensure_uncategorized_category
      execute "UPDATE products SET category_id = #{sentinel_id} WHERE category_id IS NULL"
    end

    change_column_null :products, :category_id, false
  end

  def down
    change_column_null :products, :category_id, true
    change_column_null :products, :stock_quantity, true
    change_column_null :categories, :name, true
  end

  private

  def execute_count(sql)
    ActiveRecord::Base.connection.select_value(sql).to_i
  end

  def ensure_uncategorized_category
    existing = ActiveRecord::Base.connection.select_value(
      "SELECT id FROM categories WHERE name = 'Uncategorized' LIMIT 1"
    )
    return existing.to_i if existing

    now = Time.current.utc.strftime("%Y-%m-%d %H:%M:%S")
    ActiveRecord::Base.connection.insert(
      "INSERT INTO categories (name, description, created_at, updated_at) " \
      "VALUES ('Uncategorized', 'Auto-created during NOT NULL backfill', '#{now}', '#{now}')"
    )
  end
end
