module Api
  module V1
    class ReservationsController < BaseController
      before_action :set_court, only: [:create]

      def index
        @reservations = Reservation.includes(:user, court: [:sports_complex, :sport])
                                   .order(reservation_date: :desc, start_time: :desc)
        if params[:user_id].present?
          @reservations = @reservations.where(user_id: params[:user_id])
        end

        render json: @reservations.map { |res| serialize_reservation(res) }
      end

      def show
        @reservation = Reservation.includes(:user, court: [:sports_complex, :sport]).find(params[:id])

        render json: serialize_reservation(@reservation, detailed: true)
      end

      def create
        @reservation = Reservation.new(reservation_params)
        
        # Asignar usuario si se envía o tomar el primero disponible para testing si no se especificó
        @reservation.user_id ||= params[:user_id] || User.first&.id

        # Estado inicial por defecto si no viene especificado (pending o confirmed según tu enum)
        @reservation.status ||= :pending if @reservation.respond_to?(:status)

        # Si no enviaron total_price, intentar calcularlo a partir de un time_slot coincidente
        if @reservation.total_price.blank? && @court.present?
          matching_slot = @court.time_slots.find_by(
            start_time: @reservation.start_time,
            end_time: @reservation.end_time
          )
          @reservation.total_price = matching_slot&.price || 0
        end

        if @reservation.save
          render json: serialize_reservation(@reservation, detailed: true), status: :created
        else
          render json: { errors: @reservation.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def set_court
        @court = Court.find_by(id: params.dig(:reservation, :court_id) || params[:court_id])
      end

      def reservation_params
        params.require(:reservation).permit(
          :court_id,
          :reservation_date,
          :start_time,
          :end_time,
          :total_price,
          :status,
          :user_id
        )
      end

      def serialize_reservation(reservation, detailed: false)
        data = {
          id: reservation.id,
          reservation_date: reservation.reservation_date&.strftime("%Y-%m-%d"),
          start_time: reservation.start_time&.strftime("%H:%M"),
          end_time: reservation.end_time&.strftime("%H:%M"),
          total_price: reservation.total_price.to_f,
          status: reservation.status,
          court: {
            id: reservation.court.id,
            name: reservation.court.name,
            sport: reservation.court.sport.name,
            sports_complex: {
              id: reservation.court.sports_complex.id,
              name: reservation.court.sports_complex.name,
              address: reservation.court.sports_complex.address,
              city: reservation.court.sports_complex.city
            }
          }
        }

        if detailed && reservation.user.present?
          data[:user] = {
            id: reservation.user.id,
            name: reservation.user.name,
            email: reservation.user.email
          }
        end

        data
      end
    end
  end
end