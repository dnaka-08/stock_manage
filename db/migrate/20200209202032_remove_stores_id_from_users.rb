class RemoveStoresIdFromUsers < ActiveRecord::Migration[5.2]
  def change
    remove_column :users, :stores_id, :integer
  end
end
