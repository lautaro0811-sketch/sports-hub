class Reservation < ApplicationRecord
  belongs_to :court
  belongs_to :user

  enum :status, { pending: 0, confirmed: 1, cancelled: 2 }, default: :pending

  validates :reservation_date, :start_time, :end_time, :total_price, presence: true
  validate :reservation_date_cannot_be_in_the_past
  validate :no_overlapping_reservations

  before_validation :calculate_total_price, on: :create

  def cancel!
    return false if cancelled?

    update(status: :cancelled)
  end

  private

  def calculate_total_price
    return if total_price.present? || court.blank? || start_time.blank? || end_time.blank?

    # Asigna precio de referencia si aún no se definió
    duration = ((end_time - start_time) / 1.hour).to_f
    self.total_price = duration * 5000.0 # Tarifa base
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
                             .where.not(status: :cancelled) # CAMBIO: Mantuve tu excelente lógica y alineé la cadena de consultas
                             .where("start_time < ? AND end_time > ?", end_time, start_time)

    if overlapping.exists?
      errors.add(:base, "La cancha ya se encuentra reservada en el horario seleccionado")
    end
  end
end
