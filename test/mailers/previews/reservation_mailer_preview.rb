# Preview all emails at http://localhost:3000/rails/mailers/reservation_mailer
class ReservationMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/reservation_mailer/confirmation_email
  def confirmation_email
    ReservationMailer.confirmation_email
  end
end
