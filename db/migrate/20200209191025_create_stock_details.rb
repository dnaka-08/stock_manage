class CreateStockDetails < ActiveRecord::Migration[5.2]
  def change
    create_table :stock_details do |t|
      t.references :stock, foreign_key: true
      t.references :product, foreign_key: true
      t.date :date
      t.references :operation, foreign_key: true
      t.integer :number
      t.references :user, foreign_key: true

      t.timestamps
    end
  end
end
