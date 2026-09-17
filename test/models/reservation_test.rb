require "test_helper"

class ReservationTest < ActiveSupport::TestCase
  fixtures []

  setup do
    @user = User.find_or_create_by!(email: "test_res@ejemplo.com") do |u|
      u.name = "Test"
      u.password = "password123"
    end

    @sport = Sport.find_or_create_by!(name: "Fútbol Test")

    @complex = SportsComplex.new(name: "Complejo Test", address: "Calle 123", city: "La Plata")
    @complex.save(validate: false)

    @court = Court.new(
      name: "Cancha Test",
      surface_type: "Sintético",
      sport: @sport,
      sports_complex: @complex,
      base_price: 45000.0
    )
    @court.save(validate: false)

    @tomorrow = Date.tomorrow
  end

  test "debe guardar una reserva válida" do
    reservation = Reservation.new(
      user: @user,
      court: @court,
      reservation_date: @tomorrow,
      start_time: Time.zone.parse("#{@tomorrow} 18:00"),
      end_time: Time.zone.parse("#{@tomorrow} 19:00")
    )

    assert reservation.valid?
    assert reservation.save
  end

  test "calcula automáticamente total_price según regla tarifaria de la cancha" do
    scheme = PricingScheme.create!(name: "Esquema Reserva")
    # Regla para el día de mañana
    scheme.pricing_rules.create!(
      day_of_week: @tomorrow.wday,
      start_time: "18:00",
      end_time: "23:00",
      multiplier: 1.5
    )
    @court.update!(pricing_scheme: scheme, base_price: 45000.0)

    reservation = Reservation.create!(
      user: @user,
      court: @court,
      reservation_date: @tomorrow,
      start_time: Time.zone.parse("#{@tomorrow} 18:00"),
      end_time: Time.zone.parse("#{@tomorrow} 19:00")
    )

    # 45000 * 1.5 * 1.0 = 67500.0
    assert_equal 67500.0, reservation.total_price
  end

  test "calcula total_price considerando esquema heredado del complejo" do
    scheme = PricingScheme.create!(name: "Esquema Complejo Reserva")
    scheme.pricing_rules.create!(
      day_of_week: @tomorrow.wday,
      start_time: "18:00",
      end_time: "23:00",
      multiplier: 1.3
    )
    @complex.update!(default_pricing_scheme: scheme)
    @court.update!(pricing_scheme: nil, base_price: 40000.0)

    reservation = Reservation.create!(
      user: @user,
      court: @court,
      reservation_date: @tomorrow,
      start_time: Time.zone.parse("#{@tomorrow} 18:00"),
      end_time: Time.zone.parse("#{@tomorrow} 19:00")
    )

    # 40000 * 1.3 * 1.0 = 52000.0
    assert_equal 52000.0, reservation.total_price
  end

  test "respeta total_price si fue especificado explícitamente" do
    reservation = Reservation.create!(
      user: @user,
      court: @court,
      reservation_date: @tomorrow,
      start_time: Time.zone.parse("#{@tomorrow} 18:00"),
      end_time: Time.zone.parse("#{@tomorrow} 19:00"),
      total_price: 99999.0
    )

    assert_equal 99999.0, reservation.total_price
  end

  test "no debe permitir solapamiento en la misma cancha" do
    Reservation.create!(
      user: @user,
      court: @court,
      reservation_date: @tomorrow,
      start_time: Time.zone.parse("#{@tomorrow} 18:00"),
      end_time: Time.zone.parse("#{@tomorrow} 19:00"),
      status: :confirmed
    )

    overlapping = Reservation.new(
      user: @user,
      court: @court,
      reservation_date: @tomorrow,
      start_time: Time.zone.parse("#{@tomorrow} 18:30"),
      end_time: Time.zone.parse("#{@tomorrow} 19:30")
    )

    assert_not overlapping.valid?
    assert_includes overlapping.errors[:base], "La cancha ya se encuentra reservada en el horario seleccionado"
  end

  test "debe permitir reserva si la anterior está cancelada" do
    Reservation.create!(
      user: @user,
      court: @court,
      reservation_date: @tomorrow,
      start_time: Time.zone.parse("#{@tomorrow} 18:00"),
      end_time: Time.zone.parse("#{@tomorrow} 19:00"),
      status: :cancelled
    )

    new_reservation = Reservation.new(
      user: @user,
      court: @court,
      reservation_date: @tomorrow,
      start_time: Time.zone.parse("#{@tomorrow} 18:00"),
      end_time: Time.zone.parse("#{@tomorrow} 19:00")
    )

    assert new_reservation.valid?
  end

  test "no debe permitir fechas en el pasado" do
    reservation = Reservation.new(
      user: @user,
      court: @court,
      reservation_date: Date.yesterday,
      start_time: Time.zone.parse("#{Date.yesterday} 18:00"),
      end_time: Time.zone.parse("#{Date.yesterday} 19:00")
    )

    assert_not reservation.valid?
    assert_includes reservation.errors[:reservation_date], "no puede ser en el pasado"
  end

  test "permite cancelar una reserva con más de 24 horas de anticipación" do
    target_date = 3.days.from_now.to_date
    reservation = Reservation.create!(
      user: @user,
      court: @court,
      reservation_date: target_date,
      start_time: Time.zone.parse("#{target_date} 18:00"),
      end_time: Time.zone.parse("#{target_date} 19:00"),
      status: :confirmed
    )

    assert reservation.can_be_cancelled?
    assert reservation.cancel!
    assert reservation.cancelled?
  end

  test "no permite cancelar una reserva con menos de 24 horas de anticipación" do
    # Horario dentro de las próximas 12 horas
    soon_time = 12.hours.from_now
    reservation = Reservation.create!(
      user: @user,
      court: @court,
      reservation_date: soon_time.to_date,
      start_time: soon_time,
      end_time: soon_time + 1.hour,
      status: :confirmed
    )

    assert_not reservation.can_be_cancelled?
    assert_not reservation.cancel!
    assert_includes reservation.errors[:base], "No es posible cancelar la reserva: debe realizarse con al menos 24 horas de anticipación."
    assert_not reservation.cancelled?
  end

  test "no permite cancelar una reserva ya cancelada" do
    target_date = 3.days.from_now.to_date
    reservation = Reservation.create!(
      user: @user,
      court: @court,
      reservation_date: target_date,
      start_time: Time.zone.parse("#{target_date} 18:00"),
      end_time: Time.zone.parse("#{target_date} 19:00"),
      status: :cancelled
    )

    assert_not reservation.cancel!
    assert_includes reservation.errors[:base], "La reserva ya se encuentra cancelada."
  end

  test "scopes de filtrado y ordenamiento funcionan correctamente" do
    other_complex = SportsComplex.new(name: "Otro Complejo", address: "Av 7", city: "La Plata")
    other_complex.save(validate: false)

    other_court = Court.new(
      name: "Cancha Otro",
      sport: @sport,
      sports_complex: other_complex,
      base_price: 30000.0
    )
    other_court.save(validate: false)

    res1 = Reservation.create!(
      user: @user,
      court: @court,
      reservation_date: 2.days.from_now.to_date,
      start_time: Time.zone.parse("#{2.days.from_now.to_date} 10:00"),
      end_time: Time.zone.parse("#{2.days.from_now.to_date} 11:00"),
      status: :pending
    )

    res2 = Reservation.create!(
      user: @user,
      court: other_court,
      reservation_date: 4.days.from_now.to_date,
      start_time: Time.zone.parse("#{4.days.from_now.to_date} 15:00"),
      end_time: Time.zone.parse("#{4.days.from_now.to_date} 16:00"),
      status: :confirmed
    )

    # Filtrado por complejo
    assert_includes Reservation.by_sports_complex(@complex.id), res1
    assert_not_includes Reservation.by_sports_complex(@complex.id), res2

    # Filtrado por estado
    assert_includes Reservation.by_status(:pending), res1
    assert_not_includes Reservation.by_status(:pending), res2
    assert_includes Reservation.by_status("confirmed"), res2

    # Ordenamiento
    assert_equal [res2, res1], Reservation.ordered_by_date(:desc).to_a
    assert_equal [res1, res2], Reservation.ordered_by_date(:asc).to_a
  end
end
