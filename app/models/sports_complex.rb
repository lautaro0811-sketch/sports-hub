class SportsComplex < ApplicationRecord
  has_many :courts, dependent: :destroy
  belongs_to :default_pricing_scheme, class_name: "PricingScheme", foreign_key: :default_pricing_scheme_id, optional: true
  has_one_attached :cover_photo

  validates :name, :address, :city, presence: true

  # Scopes de filtrado para administración y búsquedas
  scope :search_by_name, ->(query) {
    return all if query.blank?

    where("LOWER(sports_complexes.name) LIKE LOWER(?)", "%#{sanitize_sql_like(query.to_s.strip)}%")
  }

  scope :by_city, ->(city) {
    return all if city.blank?

    where(city: city)
  }

  def total_courts
    courts.count
  end

  def active_courts
    courts.where(is_active: true)
  end
end
