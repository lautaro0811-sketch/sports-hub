class ReservationMailer < ApplicationMailer
  default from: "notificaciones@sportshub.com"

  def confirmation_email(reservation)
    @reservation = reservation
    @user = reservation.user
    @court = reservation.court
    @complex = @court.sports_complex

    mail(to: @user.email, subject: "Confirmación de tu reserva en #{@complex.name}")
  end
end
