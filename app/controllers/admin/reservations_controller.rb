module Admin
  class ReservationsController < BaseController
    def index
      @sports_complexes = SportsComplex.order(:name)

      @reservations = Reservation.includes(:user, court: [ :sports_complex, :sport ])
                                 .by_sports_complex(params[:sports_complex_id])
                                 .by_status(params[:status])
                                 .ordered_by_date(params[:order_by_date])
    end
  end
end
