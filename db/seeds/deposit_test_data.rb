# Script para crear reservas de prueba con los 3 estados de pago.
# Ejecutar con: bin/rails runner db/seeds/deposit_test_data.rb

puts "Creando datos de prueba para el flujo de seña..."

user = User.find_by(role: :client) || User.first
court = Court.where(is_active: true).first

unless user && court
  puts "ERROR: Se necesita al menos un usuario cliente y una cancha activa."
  exit 1
end

tomorrow = Date.tomorrow
base_hour = 8

# Limpiar reservas de prueba anteriores para mañana en esta cancha
Reservation.where(court: court, reservation_date: tomorrow).destroy_all

# 1. Reserva UNPAID (pendiente de seña)
r_unpaid = Reservation.create!(
  user: user,
  court: court,
  reservation_date: tomorrow,
  start_time: Time.zone.parse("#{tomorrow} #{base_hour}:00"),
  end_time: Time.zone.parse("#{tomorrow} #{base_hour + 1}:00"),
  status: :pending,
  payment_status: :unpaid
)
puts "  ✓ Reserva UNPAID:          ##{r_unpaid.id} | $#{r_unpaid.total_price} | #{base_hour}:00-#{base_hour + 1}:00"

# 2. Reserva PARTIALLY_PAID (seña pagada, falta cobrar resto)
r_partial = Reservation.create!(
  user: user,
  court: court,
  reservation_date: tomorrow,
  start_time: Time.zone.parse("#{tomorrow} #{base_hour + 2}:00"),
  end_time: Time.zone.parse("#{tomorrow} #{base_hour + 3}:00"),
  status: :confirmed,
  payment_status: :partially_paid,
  deposit_amount: nil, # se calcula abajo
  deposit_paid_at: 1.hour.ago
)
r_partial.update!(deposit_amount: r_partial.calculate_required_deposit)
puts "  ✓ Reserva PARTIALLY_PAID:  ##{r_partial.id} | $#{r_partial.total_price} | Seña: $#{r_partial.deposit_amount} | Resto: $#{r_partial.remaining_balance}"

# 3. Reserva PAID (pagada completa)
r_paid = Reservation.create!(
  user: user,
  court: court,
  reservation_date: tomorrow,
  start_time: Time.zone.parse("#{tomorrow} #{base_hour + 4}:00"),
  end_time: Time.zone.parse("#{tomorrow} #{base_hour + 5}:00"),
  status: :confirmed,
  payment_status: :paid,
  deposit_amount: nil,
  deposit_paid_at: 2.hours.ago
)
r_paid.update!(deposit_amount: r_paid.total_price)
puts "  ✓ Reserva PAID:            ##{r_paid.id} | $#{r_paid.total_price}"

puts ""
puts "Datos creados para #{tomorrow}. Ingresá al dashboard admin y seleccioná esa fecha."
puts "La reserva ##{r_partial.id} (PARTIALLY_PAID) debería mostrar el botón 'Cobrar Resto'."
