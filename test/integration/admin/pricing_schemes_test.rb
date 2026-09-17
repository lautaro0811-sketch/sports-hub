require "test_helper"

class Admin::PricingSchemesTest < ActionDispatch::IntegrationTest
  fixtures []

  setup do
    @admin = User.create!(
      name: "Admin User",
      email: "admin_test@sportshub.com",
      password: "password123",
      role: :admin
    )

    @sport = Sport.find_or_create_by!(name: "Fútbol")
    @complex = SportsComplex.create!(name: "Complejo Test", address: "Calle 12", city: "La Plata")
    @court = Court.create!(
      name: "Cancha Principal",
      sports_complex: @complex,
      sport: @sport,
      surface_type: "Sintético",
      base_price: 45000.0,
      is_active: true
    )

    # Iniciar sesión como admin
    post login_path, params: { email: @admin.email, password: "password123" }
    follow_redirect!
  end

  test "flujo completo de esquemas tarifarios en panel de administración" do
    # 1. Acceder al índice de esquemas tarifarios
    get admin_pricing_schemes_path
    assert_response :success

    # 2. Crear un nuevo esquema
    get new_admin_pricing_scheme_path
    assert_response :success

    post admin_pricing_schemes_path, params: {
      pricing_scheme: {
        name: "Tarifa Pico Noche",
        description: "Reglas para horario nocturno"
      }
    }
    scheme = PricingScheme.find_by!(name: "Tarifa Pico Noche")
    assert_redirected_to admin_pricing_scheme_path(scheme)
    follow_redirect!
    assert_response :success

    # 3. Agregar reglas masivas para Lunes a Viernes
    post admin_pricing_scheme_pricing_rules_path(scheme), params: {
      pricing_rule: {
        days_of_week: [ 1, 2, 3, 4, 5 ],
        start_time: "18:00",
        end_time: "23:00",
        multiplier: 1.5
      }
    }
    assert_redirected_to admin_pricing_scheme_path(scheme)
    follow_redirect!
    assert_response :success
    assert_equal 5, scheme.pricing_rules.count

    # 4. Asignar el esquema a la cancha
    post assign_courts_admin_pricing_scheme_path(scheme), params: {
      court_ids: [ @court.id ]
    }
    assert_redirected_to admin_pricing_scheme_path(scheme)
    @court.reload
    assert_equal scheme.id, @court.pricing_scheme_id

    # 5. Editar una regla específica
    rule = scheme.pricing_rules.find_by!(day_of_week: 1)
    get edit_admin_pricing_scheme_pricing_rule_path(scheme, rule)
    assert_response :success

    patch admin_pricing_scheme_pricing_rule_path(scheme, rule), params: {
      pricing_rule: {
        day_of_week: 1,
        start_time: "18:00",
        end_time: "23:00",
        multiplier: 1.6
      }
    }
    assert_redirected_to admin_pricing_scheme_path(scheme)
    rule.reload
    assert_equal 1.6, rule.multiplier

    # 6. Eliminar una regla
    delete admin_pricing_scheme_pricing_rule_path(scheme, rule)
    assert_redirected_to admin_pricing_scheme_path(scheme)
    assert_equal 4, scheme.pricing_rules.count

    # 7. Eliminar el esquema tarifario
    delete admin_pricing_scheme_path(scheme)
    assert_redirected_to admin_pricing_schemes_path
    @court.reload
    assert_nil @court.pricing_scheme_id
  end
end
