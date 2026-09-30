require "test_helper"

class ReservationDepositTest < ActiveSupport::TestCase
  fixtures []

  setup do
    @user = User.find_or_create_by!(email: "deposit_test@ejemplo.com") do |u|
      u.name = "Deposit Test"
      u.password = "password123"
    end

    @sport = Sport.find_or_create_by!(name: "Fútbol Test Deposit")

    @complex = SportsComplex.new(name: "Complejo Deposit", address: "Calle 456", city: "CABA")
    @complex.save(validate: false)

    @court = Court.new(
      name: "Cancha Deposit",
      surface_type: "Sintético",
      sport: @sport,
      sports_complex: @complex,
      base_price: 50000.0
    )
    @court.save(validate: false)

    @tomorrow = Date.tomorrow
  end

  # ── Enum payment_status ──

  test "payment_status tiene 3 valores: unpaid, partially_paid, paid" do
    assert_equal({ "unpaid" => 0, "partially_paid" => 1, "paid" => 2 }, Reservation.payment_statuses)
  end

  test "payment_status por defecto es unpaid" do
    reservation = build_reservation
    assert reservation.unpaid?
  end

  # ── calculate_required_deposit ──

  test "calculate_required_deposit devuelve el 30% del total_price" do
    reservation = build_reservation(total_price: 50000.0)
    reservation.save!

    assert_equal 15000.0, reservation.calculate_required_deposit
  end

  test "calculate_required_deposit redondea a 2 decimales" do
    reservation = build_reservation(total_price: 33333.33)
    reservation.save!

    # 33333.33 * 0.30 = 10000.0 (redondeado)
    assert_equal 10000.0, reservation.calculate_required_deposit
  end

  # ── remaining_balance ──

  test "remaining_balance devuelve total_price cuando no hay depósito" do
    reservation = build_reservation(total_price: 50000.0)
    reservation.save!

    assert_equal 50000.0, reservation.remaining_balance
  end

  test "remaining_balance resta el deposit_amount del total_price" do
    reservation = build_reservation(total_price: 50000.0)
    reservation.save!
    reservation.update!(deposit_amount: 15000.0)

    assert_equal 35000.0, reservation.remaining_balance
  end

  # ── Flujo completo de seña ──

  test "flujo completo: pending/unpaid → confirmed/partially_paid → paid" do
    reservation = build_reservation
    reservation.save!

    # Estado inicial
    assert reservation.pending?
    assert reservation.unpaid?
    assert_nil reservation.deposit_amount
    assert_nil reservation.deposit_paid_at

    # Simular pago de seña (lo que haría el webhook)
    deposit = reservation.calculate_required_deposit
    reservation.update!(
      payment_status: :partially_paid,
      status: :confirmed,
      deposit_amount: deposit,
      deposit_paid_at: Time.current
    )

    assert reservation.confirmed?
    assert reservation.partially_paid?
    assert_equal deposit, reservation.deposit_amount
    assert_not_nil reservation.deposit_paid_at
    assert_equal reservation.total_price - deposit, reservation.remaining_balance

    # Simular cobro del resto (lo que haría collect_remaining)
    reservation.update!(payment_status: :paid)

    assert reservation.paid?
    assert_equal reservation.total_price - deposit, reservation.remaining_balance
  end

  private

  def build_reservation(overrides = {})
    hour = rand(8..20)
    Reservation.new({
      user: @user,
      court: @court,
      reservation_date: @tomorrow,
      start_time: Time.zone.parse("#{@tomorrow} #{hour}:00"),
      end_time: Time.zone.parse("#{@tomorrow} #{hour + 1}:00")
    }.merge(overrides))
  end
end
