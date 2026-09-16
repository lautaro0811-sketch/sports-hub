module Api
  module V1
    class ReservationsController < BaseController
      def index
        @reservations = current_user.reservations
                                    .includes(court: :sports_complex)
                                    .order(reservation_date: :desc, start_time: :desc)

        render json: @reservations.as_json(
          include: {
            court: {
              only: %i[id name surface_type],
              include: { sports_complex: { only: %i[id name address] } }
            }
          }
        ), status: :ok
      end

      def show
        @reservation = current_user.reservations.find(params[:id])

        render json: @reservation.as_json(
          include: {
            court: {
              only: %i[id name surface_type],
              include: { sports_complex: { only: %i[id name address] } }
            }
          }
        ), status: :ok
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Reserva no encontrada o no autorizada" }, status: :not_found
      end

      def create
        @reservation = current_user.reservations.build(reservation_params)

        if @reservation.save
          ReservationMailer.confirmation_email(@reservation).deliver_later

          render json: @reservation, status: :created
        else
          render json: { errors: @reservation.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def reservation_params
        params.require(:reservation).permit(
          :court_id,
          :reservation_date,
          :start_time,
          :end_time
        )
      end
    end
  end
end
