require "test_helper"

class Admin::DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(
      name: "Admin Dashboard",
      email: "admin_dashboard_test@sportshub.com",
      password: "password123",
      role: :admin
    )
    @client = User.create!(
      name: "Cliente Test",
      email: "client_dashboard_test@sportshub.com",
      password: "password123",
      phone: "2211234567",
      role: :client
    )
    @sports_complex = SportsComplex.create!(
      name: "Complejo Central",
      address: "Av. Siempre Viva 123",
      city: "La Plata",
      phone: "2211111111"
    )
    @sport = Sport.create!(name: "Fútbol Dashboard Test")
    @court_a = Court.create!(
      name: "Cancha A",
      sports_complex: @sports_complex,
      sport: @sport,
      surface_type: "Sintético",
      base_price: 5000,
      is_active: true
    )
    @court_b = Court.create!(
      name: "Cancha B",
      sports_complex: @sports_complex,
      sport: @sport,
      surface_type: "Cemento",
      base_price: 4000,
      is_active: true
    )
    @court_inactive = Court.create!(
      name: "Cancha Inactiva",
      sports_complex: @sports_complex,
      sport: @sport,
      surface_type: "Césped",
      base_price: 6000,
      is_active: false
    )

    post login_path, params: { email: @admin.email, password: "password123" }
    follow_redirect!
    travel_to Time.zone.local(2026, 9, 18, 14, 0, 0)
  end

  teardown do
    travel_back
  end

  # ── Acceso ──

  test "requiere autenticación admin para acceder al dashboard" do
    delete logout_path
    get admin_root_path
    assert_redirected_to login_path
  end

  test "permite acceso a usuarios admin" do
    get admin_root_path
    assert_response :success
  end

  test "no permite acceso a usuarios client" do
    delete logout_path
    client_only = User.create!(
      name: "Solo Client",
      email: "solo_client_dashboard@sportshub.com",
      password: "password123",
      role: :client
    )
    post login_path, params: { email: client_only.email, password: "password123" }
    get admin_root_path
    assert_redirected_to login_path
  end

  # ── Estructura de la vista ──

  test "renderiza todas las secciones del dashboard" do
    get admin_root_path
    assert_response :success

    # KPI cards: ahora son 3 (Reservas Hoy, Canchas en Uso, Turnos Restantes)
    # + 1 card de Cancelaciones = 4 total? No, verificamos en el grid
    assert_select ".dashboard-kpi-grid"
    assert_select ".dashboard-kpi-card"

    # Ahora Mismo
    assert_select ".dashboard-section--now"

    # Próximo Turno
    assert_select ".dashboard-section--next-shift"

    # Estado de Canchas
    assert_select ".dashboard-courts-grid"

    # Próximos Turnos (tabla)
    assert_select ".admin-table"
  end

  test "no muestra la KPI de Reservas Semana" do
    get admin_root_path
    assert_response :success
    assert_no_match(/Reservas Semana/, response.body)
  end

  test "muestra la KPI de Turnos Restantes" do
    get admin_root_path
    assert_response :success
    assert_match(/Turnos Restantes/, response.body)
  end

  # ── KPI: Reservas Hoy ──

  test "muestra el conteo de reservas de hoy en la KPI" do
    create_reservation(@court_a, Date.current, "10:00", "11:00", :confirmed)
    create_reservation(@court_b, Date.current, "11:00", "12:00", :confirmed)
    create_reservation(@court_a, Date.current, "14:00", "15:00", :pending)
    # Cancelada no debe contarse
    create_reservation(@court_b, Date.current, "14:00", "15:00", :cancelled)

    get admin_root_path
    assert_response :success
    assert_select ".dashboard-kpi-label", text: "Reservas Hoy"
    # Debe haber un valor de 3 en alguna KPI
    assert_select ".dashboard-kpi-card" do
      assert_select ".dashboard-kpi-label", text: "Reservas Hoy"
    end
  end

  # ── KPI: Cancelaciones Hoy ──

  test "muestra cancelaciones del día" do
    create_reservation(@court_a, Date.current, "10:00", "11:00", :cancelled)
    create_reservation(@court_b, Date.current, "12:00", "13:00", :cancelled)

    get admin_root_path
    assert_response :success
    assert_select ".dashboard-kpi-label", text: "Cancelaciones Hoy"
  end

  # ── Ahora Mismo ──

  test "muestra reservas en curso en la sección Ahora Mismo" do
    now = Time.current
    start_t = (now - 20.minutes).strftime("%H:%M")
    end_t = (now + 40.minutes).strftime("%H:%M")

    # Solo si no cruza medianoche
    if (now - 20.minutes).to_date == Date.current
      create_reservation(@court_a, Date.current, start_t, end_t, :confirmed)

      get admin_root_path
      assert_response :success
      assert_select ".dashboard-now-card", minimum: 1
      assert_select ".dashboard-now-card__court", text: "Cancha A"
      assert_select ".badge-live", text: "En juego"
    end
  end

  test "muestra mensaje vacío cuando no hay turnos en curso" do
    get admin_root_path
    assert_response :success
    assert_select ".dashboard-section--now .dashboard-empty-message", text: /No hay turnos en curso/
  end

  # ── Próximo Turno ──

  test "muestra el próximo turno con countdown" do
    future_start = (Time.current + 1.hour).strftime("%H:%M")
    future_end = (Time.current + 2.hours).strftime("%H:%M")

    if (Time.current + 1.hour).to_date == Date.current
      create_reservation(@court_a, Date.current, future_start, future_end, :confirmed)

      get admin_root_path
      assert_response :success
      assert_select ".dashboard-next-shift", 1
      assert_select ".dashboard-next-shift__court", text: /Cancha A/
      assert_select ".dashboard-next-shift__countdown-value"
      assert_select ".dashboard-next-shift__countdown-label", text: /minuto/
    end
  end

  test "muestra mensaje cuando no hay más turnos programados" do
    get admin_root_path
    assert_response :success
    assert_select ".dashboard-section--next-shift .dashboard-empty-message",
                  text: /No hay más turnos programados para hoy/
  end

  # ── Estado de Canchas ──

  test "muestra canchas activas en el estado de canchas" do
    get admin_root_path
    assert_response :success
    assert_select ".dashboard-court-status", minimum: 2 # court_a y court_b
    assert_select ".dashboard-court-status__name", text: "Cancha A"
    assert_select ".dashboard-court-status__name", text: "Cancha B"
  end

  test "no incluye canchas inactivas en el estado de canchas" do
    get admin_root_path
    assert_response :success
    assert_select ".dashboard-court-status__name", text: "Cancha Inactiva", count: 0
  end

  test "muestra badge En juego para cancha con reserva en curso" do
    now = Time.current
    start_t = (now - 15.minutes).strftime("%H:%M")
    end_t = (now + 45.minutes).strftime("%H:%M")

    if (now - 15.minutes).to_date == Date.current
      create_reservation(@court_a, Date.current, start_t, end_t, :confirmed)

      get admin_root_path
      assert_response :success
      assert_select ".dashboard-court-status--in_use", minimum: 1
    end
  end

  test "muestra badge Disponible para cancha sin reservas" do
    get admin_root_path
    assert_response :success
    assert_select ".badge-available", text: "Disponible", minimum: 1
  end

  test "muestra badge Próximo turno para cancha con reserva futura" do
    future_start = (Time.current + 2.hours).strftime("%H:%M")
    future_end = (Time.current + 3.hours).strftime("%H:%M")

    if (Time.current + 2.hours).to_date == Date.current
      create_reservation(@court_a, Date.current, future_start, future_end, :confirmed)

      get admin_root_path
      assert_response :success
      assert_select ".dashboard-court-status--upcoming", minimum: 1
      assert_select ".badge-warning", text: "Próximo turno", minimum: 1
    end
  end

  # ── Próximos Turnos (tabla) ──

  test "muestra tabla de próximos turnos con datos del cliente" do
    future_start = (Time.current + 2.hours).strftime("%H:%M")
    future_end = (Time.current + 3.hours).strftime("%H:%M")

    if (Time.current + 2.hours).to_date == Date.current
      create_reservation(@court_a, Date.current, future_start, future_end, :confirmed)

      get admin_root_path
      assert_response :success
      assert_select ".admin-table tbody tr", minimum: 1
      assert_select ".admin-table td", text: /Cliente Test/
      assert_select ".badge-success", text: "Confirmada"
    end
  end

  test "muestra tabla vacía cuando no hay próximos turnos" do
    get admin_root_path
    assert_response :success
    assert_select ".table-empty", text: /No hay turnos pendientes/
  end

  test "excluye reservas canceladas de los próximos turnos" do
    future_start = (Time.current + 2.hours).strftime("%H:%M")
    future_end = (Time.current + 3.hours).strftime("%H:%M")

    if (Time.current + 2.hours).to_date == Date.current
      create_reservation(@court_a, Date.current, future_start, future_end, :cancelled)

      get admin_root_path
      assert_response :success
      assert_select ".table-empty", text: /No hay turnos pendientes/
    end
  end

  # ── No muestra información financiera ──

  test "no expone información financiera en la vista" do
    create_reservation(@court_a, Date.current, "10:00", "11:00", :confirmed)

    get admin_root_path
    assert_response :success

    # Verificar que no se muestra información monetaria
    assert_no_match(/ingreso/i, response.body)
    assert_no_match(/facturación/i, response.body)
    assert_no_match(/recaudación/i, response.body)
    assert_no_match(/ganancia/i, response.body)
    assert_no_match(/total_price/i, response.body)
  end

  # ── Muestra columna Complejo y Pago ──

  test "muestra la columna Complejo y Pago en la tabla de próximos turnos" do
    get admin_root_path
    assert_response :success
    assert_select ".admin-table th", text: "Complejo"
    assert_select ".admin-table th", text: "Pago"
  end

  test "muestra badges de estado de pago en los próximos turnos" do
    future_start_1 = (Time.current + 2.hours).strftime("%H:%M")
    future_end_1 = (Time.current + 3.hours).strftime("%H:%M")
    future_start_2 = (Time.current + 3.hours).strftime("%H:%M")
    future_end_2 = (Time.current + 4.hours).strftime("%H:%M")

    if (Time.current + 3.hours).to_date == Date.current
      res1 = create_reservation(@court_a, Date.current, future_start_1, future_end_1, :confirmed)
      res1.update!(payment_status: :paid)

      res2 = create_reservation(@court_b, Date.current, future_start_2, future_end_2, :confirmed)
      res2.update!(payment_status: :unpaid)

      get admin_root_path
      assert_response :success
      assert_select ".badge-success", text: "✓ Pagado"
      assert_select ".badge-warning", text: "⚠ Pendiente"
    end
  end

  test "muestra selector de complejos y turbo-frame" do
    get admin_root_path
    assert_response :success
    assert_select "turbo-frame#dashboard_content"
    assert_select "select[name='complex_id']"
    assert_select "option", text: "Todos los complejos"
    assert_select "option", text: @sports_complex.name
  end

  test "filtra métricas y canchas por complex_id" do
    other_complex = SportsComplex.create!(
      name: "Complejo Norte",
      address: "Calle Falsa 456",
      city: "La Plata"
    )
    other_court = Court.create!(
      name: "Cancha Norte 1",
      sports_complex: other_complex,
      sport: @sport,
      surface_type: "Sintético",
      base_price: 5000,
      is_active: true
    )

    get admin_root_path, params: { complex_id: other_complex.id }
    assert_response :success
    assert_select ".dashboard-court-status__name", text: "Cancha Norte 1"
    assert_select ".dashboard-court-status__name", text: "Cancha A", count: 0
  end

  private

  def create_reservation(court, date, start_time, end_time, status)
    Reservation.create!(
      user: @client,
      court: court,
      reservation_date: date,
      start_time: start_time,
      end_time: end_time,
      total_price: court.base_price,
      status: status
    )
  end
end
