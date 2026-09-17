class PricingScheme < ApplicationRecord
  has_many :pricing_rules, dependent: :destroy
  has_many :courts, dependent: :nullify
  has_many :sports_complexes, foreign_key: :default_pricing_scheme_id, dependent: :nullify

  validates :name, presence: true, uniqueness: true

  # Orden natural de la semana en el panel (Lunes a Domingo)
  DAY_ORDER = [ 1, 2, 3, 4, 5, 6, 0 ].freeze

  def rule_for(date, start_time, end_time = nil)
    return nil if date.blank? || start_time.blank?

    day_of_week = date.is_a?(Integer) ? date : date.to_date.wday
    candidates = pricing_rules.select { |r| r.day_of_week == day_of_week }
    candidates.find { |r| r.covers?(start_time, end_time) }
  end

  def multiplier_for(date, start_time, end_time = nil)
    rule_for(date, start_time, end_time)&.multiplier || 1.0
  end

  def rules_grouped_by_day
    rules = pricing_rules.order(:start_time).to_a
    DAY_ORDER.each_with_object({}) do |day, hash|
      hash[day] = rules.select { |r| r.day_of_week == day }
    end
  end

  # Creación masiva para múltiples días en una sola transacción
  def add_rules(days_of_week:, start_time:, end_time:, multiplier:)
    days = Array(days_of_week).map(&:to_i).uniq
    if days.empty?
      return { success: false, errors: [ "Debe seleccionar al menos un día de la semana." ] }
    end

    created_rules = []
    errors = []

    transaction do
      days.each do |day|
        rule = pricing_rules.build(
          day_of_week: day,
          start_time: start_time,
          end_time: end_time,
          multiplier: multiplier
        )

        unless rule.save
          errors.concat(rule.errors.full_messages)
        else
          created_rules << rule
        end
      end

      if errors.any?
        raise ActiveRecord::Rollback
      end
    end

    if errors.any?
      { success: false, errors: errors.uniq }
    else
      { success: true, count: created_rules.size }
    end
  end

  # Total de canchas que utilizan este esquema (propias o heredadas por su complejo)
  def total_associated_courts
    direct_ids = courts.pluck(:id)
    inherited_ids = Court.where(sports_complex_id: sports_complexes.select(:id), pricing_scheme_id: nil).pluck(:id)
    (direct_ids + inherited_ids).uniq.size
  end
end
