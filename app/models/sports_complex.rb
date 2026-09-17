class SportsComplex < ApplicationRecord
  has_many :courts, dependent: :destroy
  belongs_to :default_pricing_scheme, class_name: "PricingScheme", foreign_key: :default_pricing_scheme_id, optional: true
  has_one_attached :cover_photo

  validates :name, :address, :city, presence: true

  def total_courts
    courts.count
  end

  def active_courts
    courts.where(is_active: true)
  end
end
