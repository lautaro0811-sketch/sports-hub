require "test_helper"

class Api::V1::DepositsControllerTest < ActionDispatch::IntegrationTest
  fixtures []

  setup do
    @user = User.find_or_create_by!(email: "deposit_api_test@ejemplo.com") do |u|
      u.name = "API Deposit Test"
      u.password = "password123"
    end

    @sport = Sport.find_or_create_by!(name: "Fútbol API Deposit")

    @complex = SportsComplex.new(name: "Complejo API Deposit", address: "Calle 789", city: "CABA")
    @complex.save(validate: false)

    @court = Court.new(
      name: "Cancha API Deposit",
      surface_type: "Sintético",
      sport: @sport,
      sports_complex: @complex,
      base_price: 60000.0
    )
    @court.save(validate: false)

    @tomorrow = Date.tomorrow

    @reservation = Reservation.create!(
      user: @user,
      court: @court,
      reservation_date: @tomorrow,
      start_time: Time.zone.parse("#{@tomorrow} 18:00"),
      end_time: Time.zone.parse("#{@tomorrow} 19:00"),
      status: :pending,
      payment_status: :unpaid
    )

    @auth_token = JsonWebToken.encode(user_id: @user.id)
    @auth_headers = { "Authorization" => "Bearer #{@auth_token}" }
  end

  # ── POST /api/v1/deposits (create) ──

  test "create genera preferencia de pago para reserva pending" do
    post api_v1_deposits_url,
         params: { reservation_id: @reservation.id },
         headers: @auth_headers,
         as: :json

    assert_response :created

    json = JSON.parse(response.body)
    assert_equal @reservation.id, json["reservation_id"]
    assert_equal @reservation.calculate_required_deposit.to_s, json["deposit_amount"].to_s
    assert json["init_point"].present?
    assert json["preference_id"].present?
  end

  test "create rechaza reserva que no es pending" do
    @reservation.update!(status: :confirmed, payment_status: :partially_paid)

    post api_v1_deposits_url,
         params: { reservation_id: @reservation.id },
         headers: @auth_headers,
         as: :json

    assert_response :unprocessable_entity
  end

  test "create requiere autenticación" do
    post api_v1_deposits_url,
         params: { reservation_id: @reservation.id },
         as: :json

    assert_response :unauthorized
  end

  test "create devuelve 404 para reserva inexistente" do
    post api_v1_deposits_url,
         params: { reservation_id: 999999 },
         headers: @auth_headers,
         as: :json

    assert_response :not_found
  end

  # ── POST /api/v1/deposits/webhook ──

  test "webhook confirma reserva y marca como partially_paid" do
    post webhook_api_v1_deposits_url,
         params: { reservation_id: @reservation.id },
         as: :json

    assert_response :ok

    @reservation.reload
    assert @reservation.confirmed?
    assert @reservation.partially_paid?
    assert_equal @reservation.calculate_required_deposit, @reservation.deposit_amount
    assert_not_nil @reservation.deposit_paid_at
  end

  test "webhook no requiere autenticación" do
    post webhook_api_v1_deposits_url,
         params: { reservation_id: @reservation.id },
         as: :json

    assert_response :ok
  end

  test "webhook rechaza reserva ya pagada parcialmente" do
    @reservation.update!(payment_status: :partially_paid, status: :confirmed)

    post webhook_api_v1_deposits_url,
         params: { reservation_id: @reservation.id },
         as: :json

    assert_response :unprocessable_entity
  end

  test "webhook devuelve 404 para reserva inexistente" do
    post webhook_api_v1_deposits_url,
         params: { reservation_id: 999999 },
         as: :json

    assert_response :not_found
  end
end
