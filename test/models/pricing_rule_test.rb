require "test_helper"

class PricingRuleTest < ActiveSupport::TestCase
  fixtures []

  setup do
    @scheme = PricingScheme.create!(name: "Esquema Reglas Test")
  end

  test "validaciones básicas de presencia y rangos válidos" do
    rule = PricingRule.new(pricing_scheme: @scheme)
    assert_not rule.valid?
    assert rule.errors[:day_of_week].any?
    assert rule.errors[:start_time].any?
    assert rule.errors[:end_time].any?

    # Multiplicador inválido (0 o negativo)
    rule.day_of_week = 1
    rule.start_time = "10:00"
    rule.end_time = "12:00"
    rule.multiplier = 0
    assert_not rule.valid?
    assert rule.errors[:multiplier].any?

    # Hora de fin anterior o igual a hora de inicio
    rule.multiplier = 1.2
    rule.end_time = "09:00"
    assert_not rule.valid?
    assert rule.errors[:end_time].any?
  end

  test "detecta y rechaza reglas superpuestas en el mismo día" do
    # Regla base: Lunes de 18:00 a 22:00
    @scheme.pricing_rules.create!(
      day_of_week: 1,
      start_time: "18:00",
      end_time: "22:00",
      multiplier: 1.5
    )

    # Caso 1: Se solapa al inicio (17:00 a 19:00)
    overlap_start = @scheme.pricing_rules.build(
      day_of_week: 1,
      start_time: "17:00",
      end_time: "19:00",
      multiplier: 1.2
    )
    assert_not overlap_start.valid?
    assert overlap_start.errors[:base].any? { |e| e.include?("se superpone") }

    # Caso 2: Se solapa al final (21:00 a 23:00)
    overlap_end = @scheme.pricing_rules.build(
      day_of_week: 1,
      start_time: "21:00",
      end_time: "23:00",
      multiplier: 1.3
    )
    assert_not overlap_end.valid?
    assert overlap_end.errors[:base].any? { |e| e.include?("se superpone") }

    # Caso 3: Queda completamente contenida dentro (19:00 a 20:00)
    overlap_inside = @scheme.pricing_rules.build(
      day_of_week: 1,
      start_time: "19:00",
      end_time: "20:00",
      multiplier: 1.1
    )
    assert_not overlap_inside.valid?
    assert overlap_inside.errors[:base].any? { |e| e.include?("se superpone") }

    # Caso 4: Envuelve completamente a la regla base (17:00 a 23:00)
    overlap_envelope = @scheme.pricing_rules.build(
      day_of_week: 1,
      start_time: "17:00",
      end_time: "23:00",
      multiplier: 1.4
    )
    assert_not overlap_envelope.valid?
    assert overlap_envelope.errors[:base].any? { |e| e.include?("se superpone") }
  end

  test "permite rangos contiguos sin considerarlos superpuestos" do
    # Regla 1: 08:00 a 18:00
    rule1 = @scheme.pricing_rules.create!(
      day_of_week: 1,
      start_time: "08:00",
      end_time: "18:00",
      multiplier: 1.0
    )

    # Regla 2: 18:00 a 23:00 (comienza exactamente donde termina la anterior)
    rule2 = @scheme.pricing_rules.build(
      day_of_week: 1,
      start_time: "18:00",
      end_time: "23:00",
      multiplier: 1.5
    )

    assert rule2.valid?, "Regla contigua debería ser válida: #{rule2.errors.full_messages}"
    assert rule2.save
  end

  test "permite mismos horarios en días diferentes" do
    # Lunes 18:00 a 23:00
    @scheme.pricing_rules.create!(
      day_of_week: 1,
      start_time: "18:00",
      end_time: "23:00",
      multiplier: 1.5
    )

    # Martes 18:00 a 23:00 (mismo horario, día distinto)
    rule_martes = @scheme.pricing_rules.build(
      day_of_week: 2,
      start_time: "18:00",
      end_time: "23:00",
      multiplier: 1.5
    )

    assert rule_martes.valid?
  end

  test "soporta rangos horarios completos cubriendo reservas internas" do
    rule = @scheme.pricing_rules.create!(
      day_of_week: 5, # Viernes
      start_time: "18:00",
      end_time: "23:00",
      multiplier: 1.5
    )

    # Una reserva interna de 19:00 a 20:00 debe estar cubierta
    assert rule.covers?("19:00", "20:00")
    # Una reserva de 20:00 a 21:00 debe estar cubierta
    assert rule.covers?("20:00", "21:00")
    # Reserva exactamente en el rango total
    assert rule.covers?("18:00", "23:00")

    # Reservas que se salen del rango no están cubiertas
    assert_not rule.covers?("17:00", "19:00")
    assert_not rule.covers?("22:00", "23:30")
  end
end

