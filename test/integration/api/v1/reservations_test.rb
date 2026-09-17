require "test_helper"

class Api::V1::ReservationsTest < ActionDispatch::IntegrationTest
  fixtures []

  setup do
    @user = User.find_or_create_by!(email: "cliente_res@sportshub.com") do |u|
      u.name = "Cliente Test"
      u.password = "password123"
    end

    @sport = Sport.find_or_create_by!(name: "Pádel Test")
    @complex = SportsComplex.new(name: "Complejo Test", address: "Calle 123")
    @complex.save(validate: false)

    @court = Court.new(name: "Cancha Central", surface_type: "Cristal", sport: @sport, sports_complex: @complex)
    @court.save(validate: false)

    @token = JsonWebToken.encode(user_id: @user.id)
    @headers = {
      "Authorization" => "Bearer #{@token}",
      "Content-Type" => "application/json"
    }
    @tomorrow = Date.tomorrow
  end

  test "crea una reserva exitosamente" do
    payload = {
      reservation: {
        court_id: @court.id,
        reservation_date: @tomorrow,
        start_time: Time.zone.parse("#{@tomorrow} 18:00"),
        end_time: Time.zone.parse("#{@tomorrow} 19:00")
      }
    }.to_json

    post api_v1_reservations_url, headers: @headers, params: payload

    assert_response :created
    assert_equal @court.id, response.parsed_body["court_id"]
    assert_equal @user.id, response.parsed_body["user_id"]
  end

  test "rechaza la reserva si colisiona con otra existente" do
    # Creamos una previa confirmada
    Reservation.create!(
      user: @user,
      court: @court,
      reservation_date: @tomorrow,
      start_time: Time.zone.parse("#{@tomorrow} 18:00"),
      end_time: Time.zone.parse("#{@tomorrow} 19:00"),
      status: :confirmed
    )

    # Intentamos crear en el mismo horario
    payload = {
      reservation: {
        court_id: @court.id,
        reservation_date: @tomorrow,
        start_time: Time.zone.parse("#{@tomorrow} 18:30"),
        end_time: Time.zone.parse("#{@tomorrow} 19:30")
      }
    }.to_json

    post api_v1_reservations_url, headers: @headers, params: payload

    assert_response :unprocessable_entity
    assert_includes response.parsed_body["errors"], "La cancha ya se encuentra reservada en el horario seleccionado"
  end

  test "cancela una reserva con más de 24 horas de anticipación exitosamente y encola email" do
    target_date = 3.days.from_now.to_date
    reservation = Reservation.create!(
      user: @user,
      court: @court,
      reservation_date: target_date,
      start_time: Time.zone.parse("#{target_date} 18:00"),
      end_time: Time.zone.parse("#{target_date} 19:00"),
      status: :confirmed
    )

    assert_enqueued_emails 1 do
      delete api_v1_reservation_url(reservation), headers: @headers
    end

    assert_response :ok
    assert_equal "Reserva cancelada exitosamente", response.parsed_body["message"]
    assert_equal "cancelled", response.parsed_body["reservation"]["status"]
    assert reservation.reload.cancelled?
  end

  test "rechaza la cancelación si faltan menos de 24 horas" do
    soon_time = 10.hours.from_now
    reservation = Reservation.create!(
      user: @user,
      court: @court,
      reservation_date: soon_time.to_date,
      start_time: soon_time,
      end_time: soon_time + 1.hour,
      status: :confirmed
    )

    delete api_v1_reservation_url(reservation), headers: @headers

    assert_response :unprocessable_entity
    assert_includes response.parsed_body["errors"], "No es posible cancelar la reserva: debe realizarse con al menos 24 horas de anticipación."
    assert_not reservation.reload.cancelled?
  end

  test "no permite cancelar la reserva de otro usuario (devuelve 404)" do
    other_user = User.create!(
      name: "Otro Usuario",
      email: "otro@sportshub.com",
      password: "password123"
    )

    target_date = 3.days.from_now.to_date
    other_reservation = Reservation.create!(
      user: other_user,
      court: @court,
      reservation_date: target_date,
      start_time: Time.zone.parse("#{target_date} 18:00"),
      end_time: Time.zone.parse("#{target_date} 19:00"),
      status: :confirmed
    )

    delete api_v1_reservation_url(other_reservation), headers: @headers

    assert_response :not_found
    assert_equal "Reserva no encontrada o no autorizada", response.parsed_body["error"]
    assert_not other_reservation.reload.cancelled?
  end
end
