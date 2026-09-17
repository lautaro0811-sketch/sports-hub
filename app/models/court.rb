class Court < ApplicationRecord
  belongs_to :sports_complex
  belongs_to :sport
  belongs_to :pricing_scheme, optional: true
  has_many :time_slots, dependent: :destroy
  has_many :reservations, dependent: :destroy
  has_one_attached :image

  validates :name, :surface_type, presence: true
  validates :base_price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  scope :active, -> { where(is_active: true) }
  scope :by_sport, ->(sport_id) { where(sport_id: sport_id) if sport_id.present? }

  def effective_pricing_scheme
    pricing_scheme || sports_complex&.default_pricing_scheme
  end

  def uses_custom_pricing_scheme?
    pricing_scheme_id.present?
  end

  def pricing_scheme_name
    if pricing_scheme_id.present?
      "#{pricing_scheme.name} (Personalizado)"
    elsif sports_complex&.default_pricing_scheme.present?
      "#{sports_complex.default_pricing_scheme.name} (Heredado de #{sports_complex.name})"
    else
      "Tarifa base (Sin esquema)"
    end
  end

  def pricing_rule_for(date, start_time, end_time = nil)
    effective_pricing_scheme&.rule_for(date, start_time, end_time)
  end

  def multiplier_for(date, start_time, end_time = nil)
    effective_pricing_scheme&.multiplier_for(date, start_time, end_time) || 1.0
  end

  def calculate_price(date, start_time, end_time)
    duration = duration_in_hours(start_time, end_time)
    mult = multiplier_for(date, start_time, end_time)
    (base_price.to_d * mult.to_d * duration.to_d).round(2)
  end

  def duration_in_hours(start_time, end_time)
    return 1.0 if start_time.blank? || end_time.blank?

    start_sec = PricingRule.seconds_since_midnight_for(start_time)
    end_sec = PricingRule.seconds_since_midnight_for(end_time)
    return 1.0 if start_sec.blank? || end_sec.blank? || end_sec <= start_sec

    ((end_sec - start_sec) / 3600.0).to_f
  end

  def available?(date, start_time, end_time)
    reservations.where(reservation_date: date)
                .where.not(status: :cancelled)
                .where("start_time < ? AND end_time > ?", end_time, start_time)
                .none?
  end
end
