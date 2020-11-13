class StockDetail < ApplicationRecord
  validates :product_id, presence: true
  validates :date, presence: true
  validates :operation_id, presence: true
  validates :number, presence: true, numericality: true
  validates :product_id, presence: true
  belongs_to :store
  belongs_to :product
  belongs_to :operation
end
