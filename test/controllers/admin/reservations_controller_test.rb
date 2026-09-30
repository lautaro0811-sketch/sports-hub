require "test_helper"

class Admin::ReservationsControllerTest < ActionDispatch::IntegrationTest
  fixtures []

  setup do
    @admin = User.find_or_create_by!(email: "admin_collect_test@ejemplo.com") do |u|
      u.name = "Admin Collect Test"
      u.password = "password123"
      u.role = :admin
    end
    @admin.update!(role: :admin) unless @admin.admin?

    @client = User.find_or_create_by!(email: "client_collect_test@ejemplo.com") do |u|
      u.name = "Client Collect Test"
      u.password = "password123"
    end

    @sport = Sport.find_or_create_by!(name: "Fútbol Admin Collect")

    @complex = SportsComplex.new(name: "Complejo Admin Collect", address: "Calle 321", city: "CABA")
    @complex.save(validate: false)

    @court = Court.new(
      name: "Cancha Admin Collect",
      surface_type: "Sintético",
      sport: @sport,
      sports_complex: @complex,
      base_price: 40000.0
    )
    @court.save(validate: false)

    @tomorrow = Date.tomorrow

    @reservation = Reservation.create!(
      user: @client,
      court: @court,
      reservation_date: @tomorrow,
      start_time: Time.zone.parse("#{@tomorrow} 20:00"),
      end_time: Time.zone.parse("#{@tomorrow} 21:00"),
      status: :confirmed,
      payment_status: :partially_paid,
      deposit_amount: 12000.0,
      deposit_paid_at: 1.hour.ago
    )

    # Login como admin via session
    post login_path, params: { email: @admin.email, password: "password123" }
    assert_response :redirect
  end

  test "collect_remaining marca reserva partially_paid como paid (HTML)" do
    patch collect_remaining_admin_reservation_path(@reservation),
          headers: { "Accept" => "text/html" }

    assert_redirected_to admin_root_path
    @reservation.reload
    assert @reservation.paid?
  end

  test "collect_remaining responde con turbo_stream" do
    patch collect_remaining_admin_reservation_path(@reservation),
          headers: { "Accept" => "text/vnd.turbo-stream.html" }

    assert_response :ok
    assert_includes response.body, "Pagado Completo"
    assert_includes response.body, "turbo-stream"

    @reservation.reload
    assert @reservation.paid?
  end

  test "collect_remaining redirige si la reserva no es partially_paid" do
    @reservation.update!(payment_status: :unpaid, status: :pending)

    patch collect_remaining_admin_reservation_path(@reservation),
          headers: { "Accept" => "text/html" }

    assert_redirected_to admin_root_path
    @reservation.reload
    assert @reservation.unpaid?
  end
end
