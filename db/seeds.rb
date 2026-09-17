puts "=================================================="
puts "  🌱 INICIANDO CARGA DE SEEDS PARA SPORTS HUB 🌱  "
puts "=================================================="

puts "\n1. Limpiando base de datos previa..."
Reservation.destroy_all
TimeSlot.destroy_all
PricingRule.destroy_all
Court.destroy_all
SportsComplex.destroy_all
PricingScheme.destroy_all
Sport.destroy_all
User.destroy_all

puts "\n2. Creando usuarios..."
admin = User.find_or_create_by!(email: "admin@sportshub.com") do |u|
  u.name = "Administrador General"
  u.phone = "2214567890"
  u.role = :admin
  u.password = "admin123"
  u.password_confirmation = "admin123"
end

cliente_carlos = User.find_or_create_by!(email: "cliente@sportshub.com") do |u|
  u.name = "Carlos Pérez"
  u.phone = "2219876543"
  u.role = :client
  u.password = "cliente123"
  u.password_confirmation = "cliente123"
end

cliente_sofia = User.find_or_create_by!(email: "sofia.gomez@sportshub.com") do |u|
  u.name = "Sofía Gómez"
  u.phone = "2215551234"
  u.role = :client
  u.password = "cliente123"
  u.password_confirmation = "cliente123"
end

cliente_martin = User.find_or_create_by!(email: "martin.rodriguez@sportshub.com") do |u|
  u.name = "Martín Rodríguez"
  u.phone = "2215554321"
  u.role = :client
  u.password = "cliente123"
  u.password_confirmation = "cliente123"
end

cliente_lucas = User.find_or_create_by!(email: "lucas.alvarez@sportshub.com") do |u|
  u.name = "Lucas Álvarez"
  u.phone = "2215557890"
  u.role = :client
  u.password = "cliente123"
  u.password_confirmation = "cliente123"
end

cliente_valentina = User.find_or_create_by!(email: "valentina.lopez@sportshub.com") do |u|
  u.name = "Valentina López"
  u.phone = "2215559876"
  u.role = :client
  u.password = "cliente123"
  u.password_confirmation = "cliente123"
end

puts "   ✓ Usuarios creados: #{User.count}"

puts "\n3. Creando deportes..."
futbol5 = Sport.find_or_create_by!(name: "Fútbol 5")
futbol6 = Sport.find_or_create_by!(name: "Fútbol 6")
futbol7 = Sport.find_or_create_by!(name: "Fútbol 7")
tenis   = Sport.find_or_create_by!(name: "Tenis")
padel   = Sport.find_or_create_by!(name: "Pádel")
basquet = Sport.find_or_create_by!(name: "Básquet")
puts "   ✓ Deportes creados: #{Sport.count}"

puts "\n4. Creando esquemas y reglas tarifarias..."
tarifa_estandar = PricingScheme.find_or_create_by!(name: "Tarifa estándar") do |s|
  s.description = "Esquema horario estándar con tarifa pico nocturna y diferenciada en fines de semana."
end

# Lunes a Viernes 08:00-18:00 -> 1.0
tarifa_estandar.add_rules(
  days_of_week: [ 1, 2, 3, 4, 5 ],
  start_time: "08:00",
  end_time: "18:00",
  multiplier: 1.0
)

# Lunes a Viernes 18:00-23:00 -> 1.5
tarifa_estandar.add_rules(
  days_of_week: [ 1, 2, 3, 4, 5 ],
  start_time: "18:00",
  end_time: "23:00",
  multiplier: 1.5
)

# Sábado 10:00-23:00 -> 1.3
tarifa_estandar.add_rules(
  days_of_week: [ 6 ],
  start_time: "10:00",
  end_time: "23:00",
  multiplier: 1.3
)

# Domingo 10:00-22:00 -> 1.2
tarifa_estandar.add_rules(
  days_of_week: [ 0 ],
  start_time: "10:00",
  end_time: "22:00",
  multiplier: 1.2
)

tarifa_promo = PricingScheme.find_or_create_by!(name: "Tarifa Promocional Pádel / Tenis") do |s|
  s.description = "Esquema especial con descuento diurno para deportes de raqueta."
end
tarifa_promo.add_rules(
  days_of_week: [ 1, 2, 3, 4, 5 ],
  start_time: "09:00",
  end_time: "17:00",
  multiplier: 0.8
)
tarifa_promo.add_rules(
  days_of_week: [ 1, 2, 3, 4, 5 ],
  start_time: "17:00",
  end_time: "23:00",
  multiplier: 1.3
)
tarifa_promo.add_rules(
  days_of_week: [ 6, 0 ],
  start_time: "09:00",
  end_time: "22:00",
  multiplier: 1.1
)

tarifa_futbol_premium = PricingScheme.find_or_create_by!(name: "Tarifa Fin de Semana Fútbol Premium") do |s|
  s.description = "Esquema para canchas premium de fútbol con recargo de alta demanda los fines de semana."
end
tarifa_futbol_premium.add_rules(
  days_of_week: [ 1, 2, 3, 4, 5 ],
  start_time: "14:00",
  end_time: "23:00",
  multiplier: 1.0
)
tarifa_futbol_premium.add_rules(
  days_of_week: [ 6, 0 ],
  start_time: "10:00",
  end_time: "23:30",
  multiplier: 1.4
)
puts "   ✓ Esquemas creados: #{PricingScheme.count}"

puts "\n5. Creando complejos deportivos..."
complejo_central = SportsComplex.find_or_create_by!(name: "Complejo Deportivo Central") do |c|
  c.address = "Calle 12 y 60"
  c.city = "La Plata"
  c.phone = "2214001122"
  c.default_pricing_scheme = tarifa_estandar
end

complejo_norte = SportsComplex.find_or_create_by!(name: "Polideportivo Norte") do |c|
  c.address = "Camino Centenario y 505"
  c.city = "Gonnet"
  c.phone = "2214883344"
end

complejo_citybell = SportsComplex.find_or_create_by!(name: "Club Atlético City Bell") do |c|
  c.address = "Calle Cantilo y 14b"
  c.city = "City Bell"
  c.phone = "2214992200"
  c.default_pricing_scheme = tarifa_futbol_premium
end

complejo_arenasur = SportsComplex.find_or_create_by!(name: "Arena Sur Deportes") do |c|
  c.address = "Avenida 7 y 80"
  c.city = "Villa Elvira"
  c.phone = "2214778899"
  c.default_pricing_scheme = tarifa_estandar
end

complejo_loshornos = SportsComplex.find_or_create_by!(name: "Sporting Club Los Hornos") do |c|
  c.address = "Avenida 66 y 143"
  c.city = "Los Hornos"
  c.phone = "2214665511"
end
puts "   ✓ Complejos deportivos creados: #{SportsComplex.count}"

puts "\n6. Creando canchas..."
# 16 Canchas: 5 Fútbol 5, 3 Fútbol 6, 2 Tenis, 2 Fútbol 7, 3 Pádel, 1 Básquet

# --- Fútbol 5 (5 canchas) ---
cancha_f5_1 = Court.find_or_create_by!(name: "Cancha Sintético A (F5)", sports_complex: complejo_central) do |c|
  c.surface_type = "Césped Sintético Forbex"
  c.is_active = true
  c.sport = futbol5
  c.base_price = 45000.0
end

cancha_f5_2 = Court.find_or_create_by!(name: "Cancha Sintético B (F5)", sports_complex: complejo_central) do |c|
  c.surface_type = "Césped Sintético Forbex"
  c.is_active = true
  c.sport = futbol5
  c.base_price = 45000.0
end

cancha_f5_3 = Court.find_or_create_by!(name: "Cancha Techada F5", sports_complex: complejo_norte) do |c|
  c.surface_type = "Sintético Techado"
  c.is_active = true
  c.sport = futbol5
  c.base_price = 48000.0
end

cancha_f5_4 = Court.find_or_create_by!(name: "La Bombonerita (F5)", sports_complex: complejo_citybell) do |c|
  c.surface_type = "Césped Sintético Monofilamento"
  c.is_active = true
  c.sport = futbol5
  c.base_price = 50000.0
end

cancha_f5_5 = Court.find_or_create_by!(name: "Cancha Los Halcones (F5)", sports_complex: complejo_loshornos) do |c|
  c.surface_type = "Césped Sintético Clásico"
  c.is_active = true
  c.sport = futbol5
  c.base_price = 40000.0
end

# --- Fútbol 6 (3 canchas) ---
cancha_f6_1 = Court.find_or_create_by!(name: "Cancha El Clásico (F6)", sports_complex: complejo_central) do |c|
  c.surface_type = "Césped Sintético Premium"
  c.is_active = true
  c.sport = futbol6
  c.base_price = 52000.0
end

cancha_f6_2 = Court.find_or_create_by!(name: "Cancha Centenario (F6)", sports_complex: complejo_norte) do |c|
  c.surface_type = "Césped Sintético Pro 60mm"
  c.is_active = true
  c.sport = futbol6
  c.base_price = 55000.0
end

cancha_f6_3 = Court.find_or_create_by!(name: "Cancha Sur Pro (F6)", sports_complex: complejo_arenasur) do |c|
  c.surface_type = "Césped Sintético Alta Densidad"
  c.is_active = true
  c.sport = futbol6
  c.base_price = 50000.0
end

# --- Tenis (2 canchas) ---
cancha_tenis_1 = Court.find_or_create_by!(name: "Cancha Tenis Polvo Central", sports_complex: complejo_central) do |c|
  c.surface_type = "Polvo de Ladrillo"
  c.is_active = true
  c.sport = tenis
  c.base_price = 28000.0
  c.pricing_scheme = tarifa_promo
end

cancha_tenis_2 = Court.find_or_create_by!(name: "Cancha Tenis Hard Court", sports_complex: complejo_norte) do |c|
  c.surface_type = "Cemento / Cemento Rápido"
  c.is_active = true
  c.sport = tenis
  c.base_price = 30000.0
end

# --- Fútbol 7 (2 canchas) ---
cancha_f7_1 = Court.find_or_create_by!(name: "Cancha Fútbol 7 Principal", sports_complex: complejo_citybell) do |c|
  c.surface_type = "Césped Natural Profesional"
  c.is_active = true
  c.sport = futbol7
  c.base_price = 65000.0
end

cancha_f7_2 = Court.find_or_create_by!(name: "Cancha Fútbol 7 Arena", sports_complex: complejo_arenasur) do |c|
  c.surface_type = "Césped Sintético Fibrilado"
  c.is_active = true
  c.sport = futbol7
  c.base_price = 60000.0
end

# --- Pádel (3 canchas) ---
cancha_padel_1 = Court.find_or_create_by!(name: "Cancha Pádel Cristal 1", sports_complex: complejo_central) do |c|
  c.surface_type = "Cristal Panorámico WPT"
  c.is_active = true
  c.sport = padel
  c.base_price = 32000.0
  c.pricing_scheme = tarifa_promo
end

cancha_padel_2 = Court.find_or_create_by!(name: "Cancha Pádel Cristal 2", sports_complex: complejo_citybell) do |c|
  c.surface_type = "Cristal Panorámico y Césped Azul"
  c.is_active = true
  c.sport = padel
  c.base_price = 34000.0
  c.pricing_scheme = tarifa_promo
end

cancha_padel_3 = Court.find_or_create_by!(name: "Cancha Pádel Techada Los Hornos", sports_complex: complejo_loshornos) do |c|
  c.surface_type = "Muro Clásico Techado"
  c.is_active = true
  c.sport = padel
  c.base_price = 28000.0
end

# --- Básquet (1 cancha) ---
cancha_basquet_1 = Court.find_or_create_by!(name: "Microestadio Básquet", sports_complex: complejo_loshornos) do |c|
  c.surface_type = "Parquet Flotante Profesional"
  c.is_active = true
  c.sport = basquet
  c.base_price = 35000.0
end

todas_las_canchas = [
  cancha_f5_1, cancha_f5_2, cancha_f5_3, cancha_f5_4, cancha_f5_5,
  cancha_f6_1, cancha_f6_2, cancha_f6_3,
  cancha_tenis_1, cancha_tenis_2,
  cancha_f7_1, cancha_f7_2,
  cancha_padel_1, cancha_padel_2, cancha_padel_3,
  cancha_basquet_1
]

puts "   ✓ Canchas creadas: #{Court.count}"

puts "\n7. Creando turnos de disponibilidad (TimeSlots)..."
# Franjas de lunes a viernes (tarde/noche) y fines de semana (mañana y tarde/noche)
turnos_semana = [
  [ "17:00", "18:00" ],
  [ "18:00", "19:00" ],
  [ "19:00", "20:00" ],
  [ "20:00", "21:00" ],
  [ "21:00", "22:00" ],
  [ "22:00", "23:00" ]
]

turnos_fin_de_semana = [
  [ "10:00", "11:00" ],
  [ "11:00", "12:00" ],
  [ "16:00", "17:00" ],
  [ "17:00", "18:00" ],
  [ "18:00", "19:00" ],
  [ "19:00", "20:00" ],
  [ "20:00", "21:00" ],
  [ "21:00", "22:00" ]
]

todas_las_canchas.each do |cancha|
  # Lunes a Viernes (1..5)
  (1..5).each do |dia|
    turnos_semana.each do |(inicio, fin)|
      TimeSlot.find_or_create_by!(court: cancha, day_of_week: dia, start_time: inicio, end_time: fin)
    end
  end

  # Sábados (6) y Domingos (0)
  [ 6, 0 ].each do |dia|
    turnos_fin_de_semana.each do |(inicio, fin)|
      TimeSlot.find_or_create_by!(court: cancha, day_of_week: dia, start_time: inicio, end_time: fin)
    end
  end
end
puts "   ✓ Franjas horarias (TimeSlots) creadas: #{TimeSlot.count}"

puts "\n8. Creando reservas de prueba..."
# Creamos reservas variadas (hoy, mañana y próximos días con distintos estados y clientes)
reservas_data = [
  # --- Hoy ---
  {
    court: cancha_f5_1,
    user: cliente_carlos,
    date: Date.current,
    start_time: "19:00",
    end_time: "20:00",
    status: :confirmed
  },
  {
    court: cancha_f6_1,
    user: cliente_sofia,
    date: Date.current,
    start_time: "20:00",
    end_time: "21:00",
    status: :confirmed
  },
  {
    court: cancha_padel_1,
    user: cliente_martin,
    date: Date.current,
    start_time: "18:00",
    end_time: "19:00",
    status: :pending
  },

  # --- Mañana ---
  {
    court: cancha_f5_2,
    user: cliente_lucas,
    date: Date.current + 1.day,
    start_time: "18:00",
    end_time: "19:00",
    status: :confirmed
  },
  {
    court: cancha_f5_4,
    user: cliente_valentina,
    date: Date.current + 1.day,
    start_time: "20:00",
    end_time: "21:00",
    status: :confirmed
  },
  {
    court: cancha_f6_2,
    user: cliente_carlos,
    date: Date.current + 1.day,
    start_time: "21:00",
    end_time: "22:00",
    status: :pending
  },
  {
    court: cancha_tenis_1,
    user: cliente_sofia,
    date: Date.current + 1.day,
    start_time: "17:00",
    end_time: "18:00",
    status: :confirmed
  },

  # --- Pasado mañana (+2 días) ---
  {
    court: cancha_f5_3,
    user: cliente_martin,
    date: Date.current + 2.days,
    start_time: "19:00",
    end_time: "20:00",
    status: :confirmed
  },
  {
    court: cancha_f6_3,
    user: cliente_lucas,
    date: Date.current + 2.days,
    start_time: "20:00",
    end_time: "21:00",
    status: :confirmed
  },
  {
    court: cancha_padel_2,
    user: cliente_valentina,
    date: Date.current + 2.days,
    start_time: "19:00",
    end_time: "20:00",
    status: :confirmed
  },
  {
    court: cancha_tenis_2,
    user: cliente_carlos,
    date: Date.current + 2.days,
    start_time: "18:00",
    end_time: "19:00",
    status: :cancelled
  },

  # --- Próximos días (+3 a +5 días) ---
  {
    court: cancha_f7_1,
    user: cliente_sofia,
    date: Date.current + 3.days,
    start_time: "18:00",
    end_time: "19:00",
    status: :confirmed
  },
  {
    court: cancha_f7_2,
    user: cliente_martin,
    date: Date.current + 4.days,
    start_time: "21:00",
    end_time: "22:00",
    status: :pending
  },
  {
    court: cancha_padel_3,
    user: cliente_lucas,
    date: Date.current + 4.days,
    start_time: "20:00",
    end_time: "21:00",
    status: :confirmed
  },
  {
    court: cancha_basquet_1,
    user: cliente_valentina,
    date: Date.current + 5.days,
    start_time: "19:00",
    end_time: "20:00",
    status: :confirmed
  },
  {
    court: cancha_f5_5,
    user: cliente_carlos,
    date: Date.current + 5.days,
    start_time: "20:00",
    end_time: "21:00",
    status: :confirmed
  }
]

reservas_data.each do |data|
  Reservation.find_or_create_by!(
    court: data[:court],
    user: data[:user],
    reservation_date: data[:date],
    start_time: data[:start_time],
    end_time: data[:end_time]
  ) do |res|
    res.status = data[:status]
  end
end

puts "   ✓ Reservas creadas: #{Reservation.count}"

puts "\n=================================================="
puts "  ✅ SEEDS CARGADOS CON ÉXITO                     "
puts "=================================================="
puts "📊 Resumen de registros:"
puts " - Usuarios:             #{User.count}"
puts " - Deportes:             #{Sport.count}"
puts " - Complejos deportivos: #{SportsComplex.count}"
puts " - Canchas:              #{Court.count}"
puts "   • Fútbol 5: #{Court.joins(:sport).where(sports: { name: 'Fútbol 5' }).count}"
puts "   • Fútbol 6: #{Court.joins(:sport).where(sports: { name: 'Fútbol 6' }).count}"
puts "   • Tenis:    #{Court.joins(:sport).where(sports: { name: 'Tenis' }).count}"
puts "   • Fútbol 7: #{Court.joins(:sport).where(sports: { name: 'Fútbol 7' }).count}"
puts "   • Pádel:    #{Court.joins(:sport).where(sports: { name: 'Pádel' }).count}"
puts "   • Básquet:  #{Court.joins(:sport).where(sports: { name: 'Básquet' }).count}"
puts " - Franjas horarias:     #{TimeSlot.count}"
puts " - Reservas de prueba:   #{Reservation.count} (Confirmadas: #{Reservation.confirmed.count}, Pendientes: #{Reservation.pending.count}, Canceladas: #{Reservation.cancelled.count})"
puts "\n🔑 Credenciales de prueba:"
puts " - Admin:   admin@sportshub.com / admin123"
puts " - Clientes (password: cliente123 para todos):"
puts "   • cliente@sportshub.com"
puts "   • sofia.gomez@sportshub.com"
puts "   • martin.rodriguez@sportshub.com"
puts "   • lucas.alvarez@sportshub.com"
puts "   • valentina.lopez@sportshub.com"
