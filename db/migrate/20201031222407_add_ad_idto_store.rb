class AddAdIdtoStore < ActiveRecord::Migration[5.2]
  def change
    add_column :stores, :ad_id, :string
  end
end
