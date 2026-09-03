class User < ApplicationRecord
  has_secure_password

  has_many :reservations, dependent: :destroy

  enum :role, { client: 0, admin: 1 }, default: :client

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 6 }, if: -> { new_record? || !password.nil? }
end