require "test_helper"

class ReservationMailerTest < ActionMailer::TestCase
  fixtures []

  setup do
    @user = User.find_or_create_by!(email: "juan@ejemplo.com") do |u|
      u.name = "Juan Perez"
      u.password = "password123"
    end

    @sport = Sport.find_or_create_by!(name: "Pádel Mailer")
    @complex = SportsComplex.new(name: "Complejo Central", address: "Av. Siempre Viva 123")
    @complex.save(validate: false)

    @court = Court.new(name: "Cancha 1", surface_type: "Cristal", sport: @sport, sports_complex: @complex)
    @court.save(validate: false)

    @reservation = Reservation.new(
      user: @user,
      court: @court,
      reservation_date: Date.tomorrow,
      start_time: Time.zone.parse("#{Date.tomorrow} 18:00"),
      end_time: Time.zone.parse("#{Date.tomorrow} 19:00"),
      total_price: 5000.0
    )
    @reservation.save(validate: false)
  end

  test "envia email de confirmacion de reserva" do
    email = ReservationMailer.confirmation_email(@reservation)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ "notificaciones@sportshub.com" ], email.from
    assert_equal [ @user.email ], email.to
    assert_match "Confirmación de tu reserva", email.subject
    assert_match "Complejo Central", email.body.encoded
  end

  test "envia email de cancelacion de reserva" do
    @reservation.update!(status: :cancelled)
    email = ReservationMailer.cancellation_email(@reservation)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal [ "notificaciones@sportshub.com" ], email.from
    assert_equal [ @user.email ], email.to
    assert_match "Cancelación de tu reserva", email.subject
    assert_match "Complejo Central", email.body.encoded
    assert_match "cancelada", email.body.encoded
  end
end
