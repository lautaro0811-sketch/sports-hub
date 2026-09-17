puts "Limpiando base de datos previa..."
Reservation.destroy_all
TimeSlot.destroy_all
PricingRule.destroy_all
Court.destroy_all
SportsComplex.destroy_all
PricingScheme.destroy_all
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

puts "Creando esquemas y reglas tarifarias..."
tarifa_estandar = PricingScheme.find_or_create_by!(name: "Tarifa estándar") do |s|
  s.description = "Esquema horario estándar con tarifa pico nocturna y diferenciada en fines de semana."
end

# Lunes a Viernes 08:00-18:00 -> 1.0
tarifa_estandar.add_rules(
  days_of_week: [1, 2, 3, 4, 5],
  start_time: "08:00",
  end_time: "18:00",
  multiplier: 1.0
)

# Lunes a Viernes 18:00-23:00 -> 1.5
tarifa_estandar.add_rules(
  days_of_week: [1, 2, 3, 4, 5],
  start_time: "18:00",
  end_time: "23:00",
  multiplier: 1.5
)

# Sábado 10:00-23:00 -> 1.3
tarifa_estandar.add_rules(
  days_of_week: [6],
  start_time: "10:00",
  end_time: "23:00",
  multiplier: 1.3
)

# Domingo 10:00-22:00 -> 1.2
tarifa_estandar.add_rules(
  days_of_week: [0],
  start_time: "10:00",
  end_time: "22:00",
  multiplier: 1.2
)

# Esquema personalizado para pádel / promocional
tarifa_promo = PricingScheme.find_or_create_by!(name: "Tarifa Promocional Pádel") do |s|
  s.description = "Esquema especial con descuento para Pádel diurno."
end
tarifa_promo.add_rules(
  days_of_week: [1, 2, 3, 4, 5],
  start_time: "09:00",
  end_time: "17:00",
  multiplier: 0.8
)
tarifa_promo.add_rules(
  days_of_week: [1, 2, 3, 4, 5],
  start_time: "17:00",
  end_time: "23:00",
  multiplier: 1.4
)

puts "Creando complejos deportivos..."
complejo_central = SportsComplex.find_or_create_by!(name: "Complejo Deportivo Central") do |c|
  c.address = "Calle 12 y 60"
  c.city = "La Plata"
  c.phone = "2214001122"
  c.default_pricing_scheme = tarifa_estandar # Heredan sus canchas
end

complejo_norte = SportsComplex.find_or_create_by!(name: "Polideportivo Norte") do |c|
  c.address = "Camino Centenario y 505"
  c.city = "Gonnet"
  c.phone = "2214883344"
end

puts "Creando canchas con precios base..."
# Hereda tarifa estándar del Complejo Central
cancha_f5_central = Court.find_or_create_by!(name: "Cancha Sintético A", sports_complex: complejo_central) do |c|
  c.surface_type = "Césped Sintético"
  c.is_active = true
  c.sport = futbol5
  c.base_price = 45000.0 # Precio base $45.000
end

# Override / Configuración personalizada: utiliza tarifa promocional
cancha_padel_central = Court.find_or_create_by!(name: "Cancha Pádel Cristal 1", sports_complex: complejo_central) do |c|
  c.surface_type = "Cristal Panorámico"
  c.is_active = true
  c.sport = padel
  c.base_price = 30000.0
  c.pricing_scheme = tarifa_promo # Override personalizado
end

# Sin esquema propio ni en complejo (Tarifa base directa)
cancha_tenis_norte = Court.find_or_create_by!(name: "Cancha Tenis Polvo", sports_complex: complejo_norte) do |c|
  c.surface_type = "Polvo de Ladrillo"
  c.is_active = true
  c.sport = tenis
  c.base_price = 25000.0
end

puts "Creando turnos de disponibilidad (TimeSlots)..."
[ cancha_f5_central, cancha_padel_central, cancha_tenis_norte ].each do |cancha|
  (1..5).each do |dia|
    TimeSlot.find_or_create_by!(court: cancha, day_of_week: dia, start_time: "18:00", end_time: "19:00") do |slot|
      slot.price = cancha.base_price
    end

    TimeSlot.find_or_create_by!(court: cancha, day_of_week: dia, start_time: "19:00", end_time: "20:00") do |slot|
      slot.price = cancha.base_price
    end

    TimeSlot.find_or_create_by!(court: cancha, day_of_week: dia, start_time: "20:00", end_time: "21:00") do |slot|
      slot.price = cancha.base_price
    end
  end
end

puts "Creando reserva de prueba..."
# Reserva para mañana
Reservation.find_or_create_by!(
  court: cancha_f5_central,
  user: cliente,
  reservation_date: Date.tomorrow,
  start_time: "18:00",
  end_time: "19:00"
) do |res|
  res.status = :confirmed
end

puts "¡Seeds cargados con éxito!"
puts "Credenciales de prueba:"
puts " - Admin:   admin@sportshub.com / admin123"
puts " - Cliente: cliente@sportshub.com / cliente123"
