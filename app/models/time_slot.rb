class TimeSlot < ApplicationRecord
  belongs_to :court

  DAYS = {
    1 => "Lunes",
    2 => "Martes",
    3 => "Miércoles",
    4 => "Jueves",
    5 => "Viernes",
    6 => "Sábado",
    0 => "Domingo"
  }.freeze

  # Orden natural de visualización de la semana: Lunes (1) a Domingo (0)
  DAY_ORDER = [ 1, 2, 3, 4, 5, 6, 0 ].freeze

  before_validation :sync_price_and_multiplier

  validates :day_of_week, presence: true, inclusion: { in: 0..6 }
  validates :start_time, :end_time, :price, presence: true
  validates :price_multiplier, presence: true, numericality: { greater_than: 0 }
  validate :valid_time_range
  validate :no_overlapping_slots

  def day_name
    DAYS[day_of_week] || "Día #{day_of_week}"
  end

  def formatted_start_time
    start_time&.strftime("%H:%M")
  end

  def formatted_end_time
    end_time&.strftime("%H:%M")
  end

  def formatted_time_range
    "#{formatted_start_time} - #{formatted_end_time}"
  end

  def duration_in_hours
    return 0.0 unless start_time && end_time

    start_sec = PricingRule.seconds_since_midnight_for(start_time)
    end_sec = PricingRule.seconds_since_midnight_for(end_time)
    return 0.0 if start_sec.blank? || end_sec.blank? || end_sec <= start_sec

    ((end_sec - start_sec) / 3600.0).round(2)
  end

  def duration_in_minutes
    (duration_in_hours * 60).round
  end

  def effective_multiplier
    court&.multiplier_for(day_of_week, start_time, end_time) || 1.0
  end

  def calculated_price
    court&.calculate_price(day_of_week, start_time, end_time) || court&.base_price || 0.0
  end

  private

  def sync_price_and_multiplier
    return unless court

    self.price_multiplier ||= effective_multiplier
    self.price ||= calculated_price
  end

  def valid_time_range
    return if start_time.blank? || end_time.blank?

    start_sec = PricingRule.seconds_since_midnight_for(start_time)
    end_sec = PricingRule.seconds_since_midnight_for(end_time)

    if start_sec.present? && end_sec.present? && end_sec <= start_sec
      errors.add(:end_time, "debe ser posterior a la hora de inicio")
    end
  end

  def no_overlapping_slots
    return if court_id.blank? || day_of_week.blank? || start_time.blank? || end_time.blank?

    my_start_sec = PricingRule.seconds_since_midnight_for(start_time)
    my_end_sec = PricingRule.seconds_since_midnight_for(end_time)
    return if my_start_sec.blank? || my_end_sec.blank?

    existing_slots = court.time_slots.where(day_of_week: day_of_week)
    existing_slots = existing_slots.where.not(id: id) if persisted?

    overlap = existing_slots.any? do |slot|
      s_sec = PricingRule.seconds_since_midnight_for(slot.start_time)
      e_sec = PricingRule.seconds_since_midnight_for(slot.end_time)
      next false if s_sec.blank? || e_sec.blank?

      # Comprobar si hay solapamiento: start1 < end2 && end1 > start2
      my_start_sec < e_sec && my_end_sec > s_sec
    end

    if overlap
      errors.add(:base, "Ya existe un turno que se solapa con el horario #{formatted_time_range} el día #{day_name}")
    end
  end
end
