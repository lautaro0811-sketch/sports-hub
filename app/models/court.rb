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

  # Filtro por deporte: acepta ID numérico o nombre del deporte (case-insensitive)
  scope :by_sport, ->(sport_param) {
    return all if sport_param.blank?

    if sport_param.to_s.match?(/\A\d+\z/)
      where(sport_id: sport_param)
    else
      joins(:sport).where("LOWER(sports.name) = LOWER(?)", sport_param.to_s.strip)
    end
  }

  # Filtro por franja horaria configurada para el día de la semana y rango horario
  scope :with_time_slot_at, ->(day_of_week, time_str) {
    where(
      "EXISTS (
        SELECT 1 FROM time_slots 
        WHERE time_slots.court_id = courts.id 
          AND time_slots.day_of_week = :wday 
          AND time_slots.start_time <= :time 
          AND time_slots.end_time > :time
      )",
      wday: day_of_week,
      time: time_str
    )
  }

  # Filtro para excluir canchas con reservas activas (no canceladas) en la fecha y hora
  scope :without_reservation_at, ->(date, time_str) {
    where(
      "NOT EXISTS (
        SELECT 1 FROM reservations 
        WHERE reservations.court_id = courts.id 
          AND reservations.reservation_date = :date 
          AND reservations.status != :cancelled_status 
          AND reservations.start_time <= :time 
          AND reservations.end_time > :time
      )",
      date: date,
      cancelled_status: Reservation.statuses[:cancelled],
      time: time_str
    )
  }

  # Scope integrador de disponibilidad
  scope :available_at, ->(date, time) {
    return all if date.blank? || time.blank?

    target_date = date.is_a?(Date) ? date : Date.parse(date.to_s)
    target_time = time.respond_to?(:strftime) ? time.strftime("%H:%M:%S") : Time.zone.parse(time.to_s)&.strftime("%H:%M:%S") || time

    with_time_slot_at(target_date.wday, target_time)
      .without_reservation_at(target_date, target_time)
  }

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
