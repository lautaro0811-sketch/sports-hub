puts "Limpiando base de datos previa..."
# Opcional: elimina registros anteriores para arrancar de cero en desarrollo
Reservation.destroy_all
TimeSlot.destroy_all
Court.destroy_all
SportsComplex.destroy_all
Sport.destroy_all
User.destroy_all

puts "Creando usuarios..."
admin = User.find_or_create_by!(email: "admin@sportshub.com") do |u|
  u.name = "Administrador General"
  u.phone = "2214567890"
  u.role = :admin
  u.password = "admin123"
  u.password_confirmation = "admin123"
end

cliente = User.find_or_create_by!(email: "cliente@sportshub.com") do |u|
  u.name = "Carlos Pérez"
  u.phone = "2219876543"
  u.role = :client
  u.password = "cliente123"
  u.password_confirmation = "cliente123"
end

puts "Creando deportes..."
futbol5 = Sport.find_or_create_by!(name: "Fútbol 5")
padel   = Sport.find_or_create_by!(name: "Pádel")
tenis   = Sport.find_or_create_by!(name: "Tenis")
basquet = Sport.find_or_create_by!(name: "Básquet")

puts "Creando complejos deportivos..."
complejo_central = SportsComplex.find_or_create_by!(name: "Complejo Deportivo Central") do |c|
  c.address = "Calle 12 y 60"
  c.city = "La Plata"
  c.phone = "2214001122"
end

complejo_norte = SportsComplex.find_or_create_by!(name: "Polideportivo Norte") do |c|
  c.address = "Camino Centenario y 505"
  c.city = "Gonnet"
  c.phone = "2214883344"
end

puts "Creando canchas..."
# Canchas de Complejo Central
cancha_f5_central = Court.find_or_create_by!(name: "Cancha Sintético A", sports_complex: complejo_central) do |c|
  c.surface_type = "Césped Sintético"
  c.is_active = true
  c.sport = futbol5
end

cancha_padel_central = Court.find_or_create_by!(name: "Cancha Pádel Cristal 1", sports_complex: complejo_central) do |c|
  c.surface_type = "Cristal Panorámico"
  c.is_active = true
  c.sport = padel
end

# Canchas de Polideportivo Norte
cancha_tenis_norte = Court.find_or_create_by!(name: "Cancha Tenis Polvo", sports_complex: complejo_norte) do |c|
  c.surface_type = "Polvo de Ladrillo"
  c.is_active = true
  c.sport = tenis
end

puts "Creando franjas horarias (TimeSlots)..."
# Generamos franjas para días de semana (Lunes a Viernes: días 1 a 5)
# Por ejemplo: turnos de 18:00 a 19:00 y de 19:00 a 20:00
[cancha_f5_central, cancha_padel_central, cancha_tenis_norte].each do |cancha|
  (1..5).each do |dia|
    TimeSlot.find_or_create_by!(court: cancha, day_of_week: dia, start_time: "18:00", end_time: "19:00") do |slot|
      slot.price = 15000.0
    end

    TimeSlot.find_or_create_by!(court: cancha, day_of_week: dia, start_time: "19:00", end_time: "20:00") do |slot|
      slot.price = 18000.0
    end

    TimeSlot.find_or_create_by!(court: cancha, day_of_week: dia, start_time: "20:00", end_time: "21:00") do |slot|
      slot.price = 20000.0
    end
  end
end

puts "Creando reserva de prueba..."
# Una reserva de prueba para mañana a las 18:00
Reservation.find_or_create_by!(
  court: cancha_f5_central,
  user: cliente,
  reservation_date: Date.tomorrow,
  start_time: "18:00",
  end_time: "19:00"
) do |res|
  res.total_price = 15000.0
  res.status = :confirmed
end

puts "¡Seeds cargados con éxito!"
puts "Credenciales de prueba:"
puts " - Admin:   admin@sportshub.com / admin123"
puts " - Cliente: cliente@sportshub.com / cliente123"