require "test_helper"

class ReservationTest < ActiveSupport::TestCase
  fixtures []

  setup do
    @user = User.find_or_create_by!(email: "test_res@ejemplo.com") do |u|
      u.name = "Test"
      u.password = "password123"
    end

    @sport = Sport.find_or_create_by!(name: "Fútbol Test")

    # Guardamos el complejo y la cancha saltando sus propias validaciones
    # para no tener que armar toda la cadena de City, Province, etc.
    @complex = SportsComplex.new(name: "Complejo Test", address: "Calle 123")
    @complex.save(validate: false)

    @court = Court.new(name: "Cancha Test", surface_type: "Sintético", sport: @sport, sports_complex: @complex)
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
end
