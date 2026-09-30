module Api
  module V1
    class CheckoutsController < BaseController
      skip_before_action :authenticate_api_user!, only: :webhook

      # POST /api/v1/checkouts
      # Genera una preferencia de pago por el monto de la seña (30% del total).
      def create
        reservation = current_user.reservations.find(params[:reservation_id])

        unless reservation.pending?
          return render json: { error: "La reserva debe estar pendiente para generar el pago de seña" },
                        status: :unprocessable_entity
        end

        deposit = reservation.calculate_required_deposit
        gateway = PaymentGateway::Mock.new
        preference = gateway.create_preference(reservation, deposit)

        render json: {
          reservation_id: reservation.id,
          deposit_amount: deposit,
          total_price: reservation.total_price,
          init_point: preference[:init_point],
          preference_id: preference[:id]
        }, status: :created
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Reserva no encontrada o no autorizada" }, status: :not_found
      end

      # POST /api/v1/checkouts/webhook
      # Recibe la confirmación de pago (mock o MercadoPago).
      # Actualiza la reserva a partially_paid + confirmed.
      def webhook
        reservation = Reservation.find_by!(id: params[:reservation_id])

        if reservation.partially_paid? || reservation.paid?
          return render json: { error: "El depósito ya fue registrado para esta reserva" },
                        status: :unprocessable_entity
        end

        reservation.update!(
          payment_status: :partially_paid,
          status: :confirmed,
          deposit_amount: reservation.calculate_required_deposit,
          deposit_paid_at: Time.current
        )

        render json: { status: "ok", reservation_id: reservation.id }, status: :ok
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Reserva no encontrada" }, status: :not_found
      end
    end
  end
end
