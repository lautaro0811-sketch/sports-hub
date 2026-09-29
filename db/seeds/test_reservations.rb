puts "Generando reservas para esta semana..."

user = User.first || User.create!(
  email: "demo_#{Time.now.to_i}@example.com",
  password: "password123",
  name: "Jugador Demo",
  phone: "1123456789"
)

courts = Court.active.limit(3)
if courts.empty?
  puts "No hay canchas activas en la base de datos."
  exit
end

start_date = Date.current - 1.day
end_date = Date.current + 5.days
created_count = 0

(start_date..end_date).each do |date|
  courts.each do |court|
    # 1. Ocupado / Confirmado
    start_1 = Time.zone.parse("10:00:00")
    end_1   = Time.zone.parse("11:30:00")

    if court.available?(date, start_1, end_1)
      res1 = Reservation.new(
        court: court, user: user, reservation_date: date,
        start_time: start_1, end_time: end_1,
        status: :confirmed, payment_status: :paid,
        total_price: court.calculate_price(date, start_1, end_1) || 1000
      )
      created_count += 1 if res1.save(validate: false)
    end

    # 2. Tarde / Pendiente
    start_2 = Time.zone.parse("16:00:00")
    end_2   = Time.zone.parse("17:00:00")

    if court.available?(date, start_2, end_2)
      res2 = Reservation.new(
        court: court, user: user, reservation_date: date,
        start_time: start_2, end_time: end_2,
        status: :pending, payment_status: :unpaid,
        total_price: court.calculate_price(date, start_2, end_2) || 800
      )
      created_count += 1 if res2.save(validate: false)
    end

    # 3. Noche / Cancelado
    start_3 = Time.zone.parse("20:00:00")
    end_3   = Time.zone.parse("21:30:00")

    if court.available?(date, start_3, end_3)
      res3 = Reservation.new(
        court: court, user: user, reservation_date: date,
        start_time: start_3, end_time: end_3,
        status: :cancelled, payment_status: :unpaid,
        total_price: court.calculate_price(date, start_3, end_3) || 1200
      )
      created_count += 1 if res3.save(validate: false)
    end
  end
end

puts "¡Listo! Se generaron #{created_count} reservas de prueba saltando validaciones de fechas pasadas."
