class Store < ApplicationRecord
  validates :name, presence: true, length: { maximum: 50 }, uniqueness: { case_sensitive: true }
  has_many :stocks, dependent: :delete_all
  has_many :stock_details, dependent: :delete_all
  has_many :users, dependent: :delete_all
end
