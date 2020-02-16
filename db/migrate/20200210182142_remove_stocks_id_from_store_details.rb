class RemoveStocksIdFromStoreDetails < ActiveRecord::Migration[5.2]
  def change
    remove_column :stock_details, :stock_id, :integer
  end
end
