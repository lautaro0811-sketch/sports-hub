require "test_helper"

class Api::V1::CourtsTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)

    @sport = Sport.find_or_create_by!(name: "Fútbol")
    @scheme = PricingScheme.find_or_create_by!(name: "Esquema Test")
    @complex = SportsComplex.first || SportsComplex.create!(name: "Complejo Test", address: "Calle 123", default_pricing_scheme: @scheme)
    @court = @complex.courts.first || @complex.courts.create!(name: "Cancha 1", surface_type: "Césped", sport: @sport, base_price: 1000, is_active: true)

    # Regla: Lunes (1), 18:00 a 20:00 con multiplicador 1.5
    @scheme.pricing_rules.find_or_create_by!(
      day_of_week: 1,
      start_time: "18:00",
      end_time: "20:00",
      multiplier: 1.5
    )

    # Franja horaria para el Lunes (1)
    @court.time_slots.find_or_create_by!(
      day_of_week: 1,
      start_time: "18:00",
      end_time: "19:00",
      price: 1000,
      price_multiplier: 1.0
    )

    @token = JsonWebToken.encode(user_id: @user.id)
    @headers = { "Authorization" => "Bearer #{@token}", "Accept" => "application/json" }
  end

  test "debe listar las canchas de un complejo con estructura de fecha y turnos" do
    # 2026-09-21 es Lunes (wday = 1)
    target_date = "2026-09-21"
    get api_v1_sports_complex_courts_url(@complex, date: target_date), headers: @headers

    assert_response :success
    body = response.parsed_body

    assert_equal target_date, body["date"]
    assert_equal 1, body["day_of_week"]
    assert_kind_of Array, body["courts"]

    court_data = body["courts"].find { |c| c["id"] == @court.id }
    assert_not_nil court_data
    assert_equal @court.name, court_data["name"]
    assert_kind_of Array, court_data["time_slots"]

    slot_data = court_data["time_slots"].first
    assert_not_nil slot_data
    assert_equal 1, slot_data["day_of_week"]
    assert_equal "18:00", slot_data["start_time"]
    assert_equal "19:00", slot_data["end_time"]
    assert_equal 1.5, slot_data["pricing"]["multiplier"]
    assert_equal 1500.0, slot_data["pricing"]["final_price"]
    assert_equal true, slot_data["available"]
  end

  test "debe mostrar los detalles de una cancha especifica con calculo de precios" do
    target_date = "2026-09-21"
    get api_v1_sports_complex_court_url(@complex, @court, date: target_date), headers: @headers

    assert_response :success
    body = response.parsed_body

    assert_equal target_date, body["date"]
    assert_equal @court.id, body["court"]["id"]
    assert_equal @court.name, body["court"]["name"]
    assert_equal 1500.0, body["court"]["time_slots"].first["pricing"]["final_price"]
  end

  test "retorna error 400 cuando el formato de fecha es invalido" do
    get api_v1_sports_complex_courts_url(@complex, date: "fecha-invalida"), headers: @headers

    assert_response :bad_request
    assert_includes response.parsed_body["error"], "Formato de fecha inválido"
  end

  test "retorna error 400 cuando el formato de hora es invalido" do
    get api_v1_sports_complex_courts_url(@complex, date: "2026-09-21", time: "hora-invalida"), headers: @headers

    assert_response :bad_request
    assert_includes response.parsed_body["error"], "Formato de hora inválido"
  end

  test "filtra canchas por nombre de deporte y por ID de deporte" do
    padel = Sport.find_or_create_by!(name: "Pádel")
    padel_court = @complex.courts.create!(name: "Cancha Pádel", surface_type: "Sintético", sport: padel, base_price: 1200, is_active: true)

    # Filtrar por nombre
    get api_v1_sports_complex_courts_url(@complex, sport: "futbol"), headers: @headers
    assert_response :success
    court_ids = response.parsed_body["courts"].map { |c| c["id"] }
    assert_includes court_ids, @court.id
    assert_not_includes court_ids, padel_court.id

    # Filtrar por ID
    get api_v1_sports_complex_courts_url(@complex, sport_id: padel.id), headers: @headers
    assert_response :success
    court_ids = response.parsed_body["courts"].map { |c| c["id"] }
    assert_includes court_ids, padel_court.id
    assert_not_includes court_ids, @court.id
  end

  test "filtra canchas por disponibilidad de fecha y hora correctamente" do
    target_date = "2026-09-21" # Lunes

    # Disponible a las 18:30 (dentro del time_slot 18:00 - 19:00)
    get api_v1_courts_url(date: target_date, time: "18:30"), headers: @headers
    assert_response :success
    court_ids = response.parsed_body["courts"].map { |c| c["id"] }
    assert_includes court_ids, @court.id

    # No disponible a las 12:00 (no hay time slot configurado)
    get api_v1_courts_url(date: target_date, time: "12:00"), headers: @headers
    assert_response :success
    court_ids = response.parsed_body["courts"].map { |c| c["id"] }
    assert_not_includes court_ids, @court.id

    # Ocupada con reserva confirmada
    Reservation.create!(
      court: @court,
      user: @user,
      reservation_date: target_date,
      start_time: "18:00",
      end_time: "19:00",
      status: :confirmed,
      total_price: 1500
    )

    get api_v1_courts_url(date: target_date, time: "18:30"), headers: @headers
    assert_response :success
    court_ids = response.parsed_body["courts"].map { |c| c["id"] }
    assert_not_includes court_ids, @court.id
  end
end

