module Admin
  class ReservationsController < BaseController
    def index
      @reservations = Reservation.includes(:user, court: [:sports_complex, :sport])
                                 .order(reservation_date: :desc, start_time: :desc)
    end
  end
end