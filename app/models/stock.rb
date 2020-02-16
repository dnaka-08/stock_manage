class Stock < ApplicationRecord
  belongs_to :store
  belongs_to :product
  has_many :stocks
end
