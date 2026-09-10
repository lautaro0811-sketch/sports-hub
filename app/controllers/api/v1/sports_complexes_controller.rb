module Api
  module V1
    class SportsComplexesController < BaseController
      def index
        @sports_complexes = SportsComplex.all
        render json: @sports_complexes, status: :ok
      end

      def show
        @sports_complex = SportsComplex.find(params[:id])
        render json: @sports_complex, status: :ok
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Complejo deportivo no encontrado" }, status: :not_found
      end
    end
  end
end
