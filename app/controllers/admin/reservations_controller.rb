module Admin
  class ReservationsController < BaseController
    def index
      @sports_complexes = SportsComplex.order(:name)

      reservations_scope = Reservation.includes(:user, court: [ :sports_complex, :sport ])
                                      .by_sports_complex(params[:sports_complex_id])
                                      .by_status(params[:status])
                                      .ordered_by_date(params[:order_by_date])

      @pagy, @reservations = pagy(reservations_scope, limit: 10)
    end
  end
end
