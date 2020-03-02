class AddStockNumberToStocks < ActiveRecord::Migration[5.2]
  def change
    add_column :stocks, :stock_number, :integer
  end
end
