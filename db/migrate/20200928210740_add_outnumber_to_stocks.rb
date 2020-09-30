class AddOutnumberToStocks < ActiveRecord::Migration[5.2]
  def change
    add_column :stocks, :out_number, :integer
  end
end
