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

    def collect_remaining
      @reservation = Reservation.find(params[:id])

      if @reservation.partially_paid?
        @reservation.update!(payment_status: :paid)

        respond_to do |format|
          format.turbo_stream
          format.html { redirect_to admin_root_path, notice: "Pago completado exitosamente." }
        end
      else
        redirect_to admin_root_path, alert: "La reserva no tiene una seña pagada para cobrar el saldo restante."
      end
    end
  end
end
