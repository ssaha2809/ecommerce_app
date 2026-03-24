class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.string :customer_name, null: false
      t.string :customer_email, null: false
      t.text :customer_address
      t.decimal :total_amount, precision: 10, scale: 2, default: 0.0
      t.string :status, default: 'pending' ## IT can be an ENUM, rails can help us with that

      t.timestamps
    end
  end
end
