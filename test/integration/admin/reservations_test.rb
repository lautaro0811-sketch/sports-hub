require "test_helper"

class Admin::ReservationsTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(
      name: "Admin User",
      email: "admin_res_test@sportshub.com",
      password: "password123",
      role: :admin
    )
    @client = User.create!(
      name: "Client User",
      email: "client_res_test@sportshub.com",
      password: "password123",
      role: :client
    )
    @sports_complex = SportsComplex.create!(
      name: "Complejo Test Central",
      address: "Av. Siempre Viva 123",
      city: "La Plata",
      phone: "2211234567"
    )
    @sport = Sport.create!(name: "Padel Test")
    @court = Court.create!(
      name: "Cancha Test 1",
      sports_complex: @sports_complex,
      sport: @sport,
      surface_type: "Sintético",
      base_price: 5000,
      is_active: true
    )

    post login_path, params: { email: @admin.email, password: "password123" }
    follow_redirect!
  end

  test "debe listar reservas y mostrar paginación cuando hay más de 10 registros" do
    # Crear 15 reservas para forzar la paginación con límite de 10
    15.times do |i|
      Reservation.create!(
        user: @client,
        court: @court,
        reservation_date: Date.current + (i + 1).days,
        start_time: "10:00",
        end_time: "11:00",
        total_price: 5000,
        status: :confirmed
      )
    end

    get admin_reservations_path
    assert_response :success

    # Debe contener el contenedor de paginación
    assert_select ".pagination-container"
    assert_select ".pagination-info", text: /Mostrando 1 - 10 de/
    assert_select ".pagination-links nav.pagy"

    # Navegar a la segunda página
    get admin_reservations_path(page: 2)
    assert_response :success
    assert_select ".pagination-info", text: /Mostrando 11 -/
  end

  test "mantiene los filtros aplicados en los enlaces de paginación" do
    12.times do |i|
      Reservation.create!(
        user: @client,
        court: @court,
        reservation_date: Date.current + (i + 1).days,
        start_time: "12:00",
        end_time: "13:00",
        total_price: 5000,
        status: :confirmed
      )
    end

    get admin_reservations_path(sports_complex_id: @sports_complex.id, status: "confirmed")
    assert_response :success
    assert_select ".pagination-container"
    assert_select ".pagination-links a[href*='sports_complex_id=#{@sports_complex.id}']"
  end
end

