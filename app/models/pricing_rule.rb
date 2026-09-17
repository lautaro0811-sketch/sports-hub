class PricingRule < ApplicationRecord
  belongs_to :pricing_scheme

  DAYS = {
    1 => "Lunes",
    2 => "Martes",
    3 => "Miércoles",
    4 => "Jueves",
    5 => "Viernes",
    6 => "Sábado",
    0 => "Domingo"
  }.freeze

  validates :day_of_week, presence: true, inclusion: { in: 0..6 }
  validates :start_time, :end_time, presence: true
  validates :multiplier, presence: true, numericality: { greater_than: 0 }
  validate :valid_time_range
  validate :no_overlapping_rules

  scope :ordered, -> { order(:day_of_week, :start_time) }

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

  def start_time_seconds
    self.class.seconds_since_midnight_for(start_time)
  end

  def end_time_seconds
    self.class.seconds_since_midnight_for(end_time)
  end

  def covers?(query_start_time, query_end_time = nil)
    q_start = self.class.seconds_since_midnight_for(query_start_time)
    return false unless q_start

    if query_end_time.present?
      q_end = self.class.seconds_since_midnight_for(query_end_time)
      return false unless q_end
      start_time_seconds <= q_start && q_end <= end_time_seconds
    else
      start_time_seconds <= q_start && q_start < end_time_seconds
    end
  end

  def self.seconds_since_midnight_for(time_val)
    return nil if time_val.blank?

    if time_val.is_a?(String)
      parts = time_val.split(":")
      parts[0].to_i * 3600 + parts[1].to_i * 60 + (parts[2] || 0).to_i
    elsif time_val.respond_to?(:seconds_since_midnight)
      time_val.seconds_since_midnight.to_i
    else
      time_val.to_time.seconds_since_midnight.to_i
    end
  end

  private

  def valid_time_range
    return if start_time.blank? || end_time.blank?

    if end_time_seconds <= start_time_seconds
      errors.add(:end_time, "debe ser posterior a la hora de inicio")
    end
  end

  def no_overlapping_rules
    return if pricing_scheme.blank? || day_of_week.blank? || start_time.blank? || end_time.blank?
    return if end_time_seconds <= start_time_seconds

    existing_rules = pricing_scheme.pricing_rules.where(day_of_week: day_of_week)
    existing_rules = existing_rules.where.not(id: id) if persisted?

    existing_rules.each do |other|
      other_start = other.start_time_seconds
      other_end = other.end_time_seconds
      next unless other_start && other_end

      if start_time_seconds < other_end && end_time_seconds > other_start
        errors.add(:base, "El rango horario (#{formatted_time_range}) se superpone con la regla #{other.formatted_time_range} para #{day_name}")
        break
      end
    end
  end
end
