class Product < ApplicationRecord
  validates :name, presence: true, length: { maximum: 50 }, uniqueness: { case_sensitive: true }
  has_many :stocks
  has_many :stock_details
end
