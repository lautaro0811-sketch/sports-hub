require "test_helper"

class CourtTest < ActiveSupport::TestCase
  fixtures []

  setup do
    @sport = Sport.find_or_create_by!(name: "Fútbol Test")
    @complex = SportsComplex.new(name: "Complejo Test", address: "Calle 123", city: "La Plata")
    @complex.save(validate: false)

    @court = Court.new(
      name: "Cancha 1",
      surface_type: "Césped sintético",
      sport: @sport,
      sports_complex: @complex,
      base_price: 45000.0
    )
    @court.save(validate: false)
  end

  test "permite adjuntar una imagen a la cancha" do
    @court.image.attach(
      io: StringIO.new("fake-image-content"),
      filename: "cancha.png",
      content_type: "image/png"
    )

    assert @court.image.attached?
  end

  test "hereda el esquema tarifario predeterminado del complejo deportivo" do
    scheme_complejo = PricingScheme.create!(name: "Tarifa Complejo Test")
    scheme_complejo.pricing_rules.create!(
      day_of_week: 1,
      start_time: "18:00",
      end_time: "23:00",
      multiplier: 1.5
    )
    @complex.update!(default_pricing_scheme: scheme_complejo)

    # La cancha no tiene pricing_scheme_id propio (es nil)
    assert_nil @court.pricing_scheme_id
    assert_equal scheme_complejo, @court.effective_pricing_scheme
    assert_equal 1.5, @court.multiplier_for(1, "19:00", "20:00")
  end

  test "soporta override / configuración personalizada anulando la del complejo" do
    scheme_complejo = PricingScheme.create!(name: "Tarifa General")
    scheme_complejo.pricing_rules.create!(
      day_of_week: 1,
      start_time: "18:00",
      end_time: "23:00",
      multiplier: 1.2
    )
    @complex.update!(default_pricing_scheme: scheme_complejo)

    # Esquema personalizado asignado a la cancha
    scheme_cancha = PricingScheme.create!(name: "Tarifa VIP Cancha")
    scheme_cancha.pricing_rules.create!(
      day_of_week: 1,
      start_time: "18:00",
      end_time: "23:00",
      multiplier: 1.8
    )
    @court.update!(pricing_scheme: scheme_cancha)

    # Debe usar el esquema de la cancha (1.8) y no el del complejo (1.2)
    assert @court.uses_custom_pricing_scheme?
    assert_equal scheme_cancha, @court.effective_pricing_scheme
    assert_equal 1.8, @court.multiplier_for(1, "19:00", "20:00")
  end

  test "calcula correctamente el precio final con regla tarifaria y duración" do
    scheme = PricingScheme.create!(name: "Tarifa Estándar")
    scheme.pricing_rules.create!(
      day_of_week: 1,
      start_time: "18:00",
      end_time: "23:00",
      multiplier: 1.5
    )
    @court.update!(pricing_scheme: scheme, base_price: 45000.0)

    # Lunes a las 18:00 por 1 hora -> 45000 * 1.5 * 1.0 = 67500.0
    price_1_hour = @court.calculate_price(1, "18:00", "19:00")
    assert_equal 67500.0, price_1_hour

    # Lunes a las 18:00 por 2 horas -> 45000 * 1.5 * 2.0 = 135000.0
    price_2_hours = @court.calculate_price(1, "18:00", "20:00")
    assert_equal 135000.0, price_2_hours
  end

  test "aplica multiplicador 1.0 en ausencia de regla tarifaria o esquema" do
    # Cancha sin esquema tarifario
    @court.update!(pricing_scheme: nil, base_price: 45000.0)
    @complex.update!(default_pricing_scheme: nil)

    price = @court.calculate_price(1, "18:00", "19:00")
    assert_equal 45000.0, price
  end
end
