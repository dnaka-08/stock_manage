class AddUserNameToStockDetails < ActiveRecord::Migration[5.2]
  def change
    add_column :stock_details, :user_name, :string
  end
end
