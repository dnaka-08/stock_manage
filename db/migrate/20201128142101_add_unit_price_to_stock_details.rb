class AddUnitPriceToStockDetails < ActiveRecord::Migration[5.2]
  def change
    add_column :stock_details, :unit_price, :integer
  end
end
