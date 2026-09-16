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
end
