class AddPriceToStockDetails < ActiveRecord::Migration[5.2]
  def change
    add_column :stock_details, :price, :integer
  end
end
