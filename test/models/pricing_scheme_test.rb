require "test_helper"

class PricingSchemeTest < ActiveSupport::TestCase
  fixtures []

  setup do
    @scheme = PricingScheme.create!(
      name: "Tarifa estándar test",
      description: "Esquema para pruebas unitarias"
    )
  end

  test "debe requerir un nombre y que sea único" do
    invalid_scheme = PricingScheme.new(name: nil)
    assert_not invalid_scheme.valid?
    assert invalid_scheme.errors[:name].any?

    duplicate_scheme = PricingScheme.new(name: "Tarifa estándar test")
    assert_not duplicate_scheme.valid?
    assert duplicate_scheme.errors[:name].any?
  end

  test "debe permitir generar reglas para múltiples días automáticamente" do
    # Lunes a Viernes (1 al 5)
    result = @scheme.add_rules(
      days_of_week: [1, 2, 3, 4, 5],
      start_time: "18:00",
      end_time: "23:00",
      multiplier: 1.5
    )

    assert result[:success]
    assert_equal 5, result[:count]
    assert_equal 5, @scheme.pricing_rules.count

    (1..5).each do |dia|
      rule = @scheme.pricing_rules.find_by(day_of_week: dia)
      assert_not_nil rule
      assert_equal 1.5, rule.multiplier
      assert_equal "18:00", rule.formatted_start_time
      assert_equal "23:00", rule.formatted_end_time
    end
  end

  test "debe revertir la transacción si uno de los múltiples días tiene conflicto" do
    # Regla previa para el miércoles (3)
    @scheme.pricing_rules.create!(
      day_of_week: 3,
      start_time: "17:00",
      end_time: "20:00",
      multiplier: 1.2
    )

    # Intentamos crear masivamente de lunes a viernes 18:00 a 22:00 (colisiona con miércoles)
    result = @scheme.add_rules(
      days_of_week: [1, 2, 3, 4, 5],
      start_time: "18:00",
      end_time: "22:00",
      multiplier: 1.5
    )

    assert_not result[:success]
    assert_includes result[:errors].first, "se superpone"
    # Solo debe quedar la regla original del miércoles
    assert_equal 1, @scheme.pricing_rules.count
  end

  test "selección de la regla correspondiente según día y horario" do
    # Lunes 08:00-18:00 -> 1.0
    @scheme.pricing_rules.create!(
      day_of_week: 1,
      start_time: "08:00",
      end_time: "18:00",
      multiplier: 1.0
    )

    # Lunes 18:00-23:00 -> 1.5
    @scheme.pricing_rules.create!(
      day_of_week: 1,
      start_time: "18:00",
      end_time: "23:00",
      multiplier: 1.5
    )

    # Sábado 10:00-23:00 -> 1.3
    @scheme.pricing_rules.create!(
      day_of_week: 6,
      start_time: "10:00",
      end_time: "23:00",
      multiplier: 1.3
    )

    # Domingo 10:00-22:00 -> 1.2
    @scheme.pricing_rules.create!(
      day_of_week: 0,
      start_time: "10:00",
      end_time: "22:00",
      multiplier: 1.2
    )

    # Lunes diurno (10:00 - 11:00)
    rule_lunes_dia = @scheme.rule_for(1, "10:00", "11:00")
    assert_equal 1.0, rule_lunes_dia.multiplier

    # Lunes nocturno (18:30 - 19:30)
    rule_lunes_noche = @scheme.rule_for(1, "18:30", "19:30")
    assert_equal 1.5, rule_lunes_noche.multiplier

    # Sábado tarde (15:00 - 16:00)
    rule_sabado = @scheme.rule_for(6, "15:00", "16:00")
    assert_equal 1.3, rule_sabado.multiplier

    # Domingo mediodía (12:00 - 13:00)
    rule_domingo = @scheme.rule_for(0, "12:00", "13:00")
    assert_equal 1.2, rule_domingo.multiplier
  end

  test "ausencia de una regla retorna nil y multiplicador 1.0" do
    # Martes (2) no tiene ninguna regla creada
    assert_nil @scheme.rule_for(2, "18:00", "19:00")
    assert_equal 1.0, @scheme.multiplier_for(2, "18:00", "19:00")
  end
end

