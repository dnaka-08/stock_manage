class AddStockDetailRefToStores < ActiveRecord::Migration[5.2]
  def change
    add_reference :stock_details, :store, foreign_key: true
  end
end
