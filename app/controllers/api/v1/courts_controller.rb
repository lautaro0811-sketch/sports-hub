module Api
  module V1
    class CourtsController < BaseController
      before_action :set_sports_complex, if: -> { params[:sports_complex_id].present? }
      before_action :set_target_date, only: %i[index show]

      def index
        base_scope = @sports_complex ? @sports_complex.courts : Court.all

        @courts = base_scope.active
                            .includes(
                              :sport,
                              :time_slots,
                              :pricing_scheme => :pricing_rules,
                              :sports_complex => { default_pricing_scheme: :pricing_rules },
                              :reservations
                            )

        # Filtro por Deporte (ID o Nombre)
        sport_param = search_params[:sport].presence || search_params[:sport_id].presence
        @courts = @courts.by_sport(sport_param) if sport_param.present?

        # Filtro de Disponibilidad por Fecha y Hora
        if search_params[:time].present?
          return unless validate_time_format!(search_params[:time])

          @courts = @courts.available_at(@date, search_params[:time])
        end
      end

      def show
        scope = @sports_complex ? @sports_complex.courts : Court.all
        @court = scope.includes(
                        :sport,
                        :time_slots,
                        :pricing_scheme => :pricing_rules,
                        :sports_complex => { default_pricing_scheme: :pricing_rules },
                        :reservations
                      )
                      .find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Cancha no encontrada" }, status: :not_found
      end

      private

      def search_params
        params.permit(:sport, :sport_id, :date, :time, :sports_complex_id)
      end

      def set_sports_complex
        @sports_complex = SportsComplex.find(params[:sports_complex_id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Complejo deportivo no encontrado" }, status: :not_found
      end

      def set_target_date
        @date = if search_params[:date].present?
                  Date.parse(search_params[:date].to_s)
                else
                  Date.current
                end
      rescue Date::Error
        render json: { error: "Formato de fecha inválido. Usar YYYY-MM-DD" }, status: :bad_request
      end

      def validate_time_format!(time_str)
        unless time_str.to_s.match?(/\A([01]\d|2[0-3]):[0-5]\d(:[0-5]\d)?\z/)
          render json: { error: "Formato de hora inválido. Usar HH:MM (ej: 19:00)" }, status: :bad_request
          return false
        end
        true
      end
    end
  end
end
