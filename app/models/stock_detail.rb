class StockDetail < ApplicationRecord
  belongs_to :store
  belongs_to :product
  belongs_to :operation
  belongs_to :user
end
