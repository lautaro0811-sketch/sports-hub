module Api
  module V1
    class CourtsController < BaseController
      before_action :set_sports_complex

      def index
        @courts = @sports_complex.courts
        render json: @courts, status: :ok
      end

      def show
        @court = @sports_complex.courts.find(params[:id])
        render json: @court, status: :ok
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Cancha no encontrada en este complejo" }, status: :not_found
      end

      private

      def set_sports_complex
        @sports_complex = SportsComplex.find(params[:sports_complex_id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Complejo deportivo no encontrado" }, status: :not_found
      end
    end
  end
end
