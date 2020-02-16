class CreateStocks < ActiveRecord::Migration[5.2]
  def change
    create_table :stocks do |t|
      t.references :store, foreign_key: true
      t.references :product, foreign_key: true
      t.date :date
      t.integer :total_number

      t.timestamps
    end
  end
end
