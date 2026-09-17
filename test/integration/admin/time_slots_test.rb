require "test_helper"

class Admin::TimeSlotsTest < ActionDispatch::IntegrationTest
  fixtures []

  setup do
    @admin = User.create!(
      name: "Admin User",
      email: "admin_timeslots@sportshub.com",
      password: "password123",
      role: :admin
    )

    @sport = Sport.find_or_create_by!(name: "Pádel")
    @complex = SportsComplex.create!(name: "Complejo Central", address: "Av. Siempre Viva 742", city: "Córdoba")
    @scheme = PricingScheme.create!(name: "Tarifa Nocturna")
    @scheme.pricing_rules.create!(
      day_of_week: 1, # Lunes
      start_time: "19:00",
      end_time: "23:00",
      multiplier: 1.5
    )

    @court = Court.create!(
      name: "Cancha Cristal 1",
      sports_complex: @complex,
      sport: @sport,
      surface_type: "Cristal Templado",
      base_price: 30000.0,
      pricing_scheme: @scheme,
      is_active: true
    )

    # Iniciar sesión de admin
    post login_path, params: { email: @admin.email, password: "password123" }
    follow_redirect!
  end

  test "accede a la pantalla de disponibilidad semanal y muestra información clara" do
    get admin_court_time_slots_path(@court)
    assert_response :success

    # Títulos y textos aclaratorios
    assert_select "h1", text: /Disponibilidad Semanal y Turnos: Cancha Cristal 1/
    assert_select "strong", text: "¿Para qué sirve esta pantalla?"
    assert_select "h2", text: "Habilitar Turnos de Reserva"
    assert_select "h2", text: "Cronograma Semanal de Disponibilidad"
  end

  test "generador masivo crea turnos de 60 minutos para múltiples días" do
    # De 18:00 a 21:00 en bloques de 60 min para Lunes (1) y Martes (2) = 3 turnos x 2 días = 6 turnos
    assert_difference -> { @court.time_slots.count }, 6 do
      post admin_court_time_slots_path(@court), params: {
        days_of_week: ["1", "2"],
        start_time: "18:00",
        end_time: "21:00",
        slot_duration: "60"
      }
    end

    assert_redirected_to admin_court_time_slots_path(@court)
    follow_redirect!
    assert_match(/Se generaron exitosamente 6 turno\(s\)/, flash[:notice])

    # Verificar que los turnos fueron 18-19, 19-20, 20-21 para el lunes
    monday_slots = @court.time_slots.where(day_of_week: 1).order(:start_time)
    assert_equal 3, monday_slots.count
    assert_equal "18:00", monday_slots[0].formatted_start_time
    assert_equal "19:00", monday_slots[0].formatted_end_time
    assert_equal "19:00", monday_slots[1].formatted_start_time
    assert_equal "20:00", monday_slots[1].formatted_end_time
    assert_equal "20:00", monday_slots[2].formatted_start_time
    assert_equal "21:00", monday_slots[2].formatted_end_time

    # Verificar cálculo automático de precio y multiplicador para el turno de 19:00 (regla con mult 1.5)
    slot_pico = monday_slots[1]
    assert_equal 1.5, slot_pico.effective_multiplier
    assert_equal 45000.0, slot_pico.calculated_price
  end

  test "generador masivo crea turnos de 90 minutos para pádel" do
    # De 18:00 a 21:00 en bloques de 90 min = 2 turnos (18:00-19:30, 19:30-21:00) para Miércoles (3)
    assert_difference -> { @court.time_slots.count }, 2 do
      post admin_court_time_slots_path(@court), params: {
        days_of_week: ["3"],
        start_time: "18:00",
        end_time: "21:00",
        slot_duration: "90"
      }
    end

    wednesday_slots = @court.time_slots.where(day_of_week: 3).order(:start_time)
    assert_equal 2, wednesday_slots.count
    assert_equal "18:00", wednesday_slots[0].formatted_start_time
    assert_equal "19:30", wednesday_slots[0].formatted_end_time
    assert_equal "19:30", wednesday_slots[1].formatted_start_time
    assert_equal "21:00", wednesday_slots[1].formatted_end_time
  end

  test "crea turno único con franja completa sin dividir" do
    assert_difference -> { @court.time_slots.count }, 1 do
      post admin_court_time_slots_path(@court), params: {
        days_of_week: ["5"], # Viernes
        start_time: "21:00",
        end_time: "23:00",
        slot_duration: "exact"
      }
    end

    slot = @court.time_slots.where(day_of_week: 5).first
    assert_equal "21:00", slot.formatted_start_time
    assert_equal "23:00", slot.formatted_end_time
    assert_equal 2.0, slot.duration_in_hours
  end

  test "elimina un turno individual" do
    slot = @court.time_slots.create!(
      day_of_week: 1,
      start_time: "15:00",
      end_time: "16:00",
      price: 30000.0
    )

    assert_difference -> { @court.time_slots.count }, -1 do
      delete admin_court_time_slot_path(@court, slot)
    end

    assert_redirected_to admin_court_time_slots_path(@court)
  end

  test "vaciar turnos de un día específico (destroy_day)" do
    @court.time_slots.create!(day_of_week: 1, start_time: "15:00", end_time: "16:00", price: 30000.0)
    @court.time_slots.create!(day_of_week: 1, start_time: "16:00", end_time: "17:00", price: 30000.0)
    @court.time_slots.create!(day_of_week: 2, start_time: "15:00", end_time: "16:00", price: 30000.0)

    assert_difference -> { @court.time_slots.count }, -2 do
      delete destroy_day_admin_court_time_slots_path(@court, day_of_week: 1)
    end

    assert_equal 0, @court.time_slots.where(day_of_week: 1).count
    assert_equal 1, @court.time_slots.where(day_of_week: 2).count
  end

  test "vaciar todos los turnos de la cancha (destroy_all)" do
    @court.time_slots.create!(day_of_week: 1, start_time: "15:00", end_time: "16:00", price: 30000.0)
    @court.time_slots.create!(day_of_week: 2, start_time: "15:00", end_time: "16:00", price: 30000.0)

    assert_difference -> { @court.time_slots.count }, -2 do
      delete destroy_all_admin_court_time_slots_path(@court)
    end

    assert_equal 0, @court.time_slots.count
  end

  test "rechaza creación sin seleccionar días" do
    post admin_court_time_slots_path(@court), params: {
      days_of_week: [],
      start_time: "18:00",
      end_time: "20:00"
    }

    assert_redirected_to admin_court_time_slots_path(@court)
    assert_match(/Debés seleccionar al menos un día/, flash[:alert])
  end
end

