class User < ApplicationRecord
  validates :user_id, presence: true, length: { maximum: 10 }, uniqueness: { case_sensitive: true }
  validates :name, presence: true, length: { maximum: 255 }
  has_secure_password
end
