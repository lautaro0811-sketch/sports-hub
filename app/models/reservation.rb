class Reservation < ApplicationRecord
  belongs_to :court
  belongs_to :user

  enum :status, { pending: 0, confirmed: 1, cancelled: 2 }, default: :pending

  scope :by_sports_complex, ->(complex_id) {
    joins(:court).where(courts: { sports_complex_id: complex_id }) if complex_id.present?
  }

  scope :by_status, ->(status) {
    where(status: status) if status.present?
  }

  scope :ordered_by_date, ->(direction = :desc) {
    dir = direction.to_s.downcase == "asc" ? :asc : :desc
    order(reservation_date: dir, start_time: dir)
  }

  validates :reservation_date, :start_time, :end_time, :total_price, presence: true
  validate :reservation_date_cannot_be_in_the_past
  validate :no_overlapping_reservations

  before_validation :calculate_total_price, on: :create

  CANCELLATION_DEADLINE_HOURS = 24

  def start_datetime
    return nil if reservation_date.blank? || start_time.blank?

    Time.zone.local(
      reservation_date.year,
      reservation_date.month,
      reservation_date.day,
      start_time.hour,
      start_time.min,
      start_time.sec
    )
  end

  def can_be_cancelled?
    return false if cancelled?
    return false if start_datetime.blank?

    start_datetime >= CANCELLATION_DEADLINE_HOURS.hours.from_now
  end

  def cancel!
    if cancelled?
      errors.add(:base, "La reserva ya se encuentra cancelada.")
      return false
    end

    unless can_be_cancelled?
      errors.add(
        :base,
        "No es posible cancelar la reserva: debe realizarse con al menos #{CANCELLATION_DEADLINE_HOURS} horas de anticipación."
      )
      return false
    end

    update(status: :cancelled)
  end

  private

  def calculate_total_price
    return if total_price.present? || court.blank? || start_time.blank? || end_time.blank?

    self.total_price = court.calculate_price(reservation_date, start_time, end_time)
  end

  # no reservar fechas anteriores
  def reservation_date_cannot_be_in_the_past
    return if reservation_date.blank?

    if reservation_date < Date.current
      errors.add(:reservation_date, "no puede ser en el pasado")
    end
  end

  # evita la colision
  def no_overlapping_reservations
    return if court_id.blank? || reservation_date.blank? || start_time.blank? || end_time.blank?

    overlapping = Reservation.where(court_id: court_id, reservation_date: reservation_date)
                             .where.not(id: id)
                             .where.not(status: :cancelled)
                             .where("start_time < ? AND end_time > ?", end_time, start_time)

    if overlapping.exists?
      errors.add(:base, "La cancha ya se encuentra reservada en el horario seleccionado")
    end
  end
end
