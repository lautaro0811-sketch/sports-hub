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

    # PATCH /admin/reservations/:id/collect_remaining
    def collect_remaining
      @reservation = Reservation.find(params[:id])

      unless @reservation.partially_paid?
        redirect_to admin_root_path, alert: "Solo se puede cobrar el resto de reservas con seña pagada." and return
      end

      @reservation.update!(payment_status: :paid)

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to admin_root_path, notice: "Pago completo registrado." }
      end
    end
  end
end
