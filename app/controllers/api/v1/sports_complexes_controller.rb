module Api
  module V1
    class SportsComplexesController < BaseController
      skip_before_action :authenticate_api_user!, only: %i[index show]

      def index
        @sports_complexes = SportsComplex.all
        render json: @sports_complexes.as_json(
          only: %i[id name address city],
          methods: %i[cover_photo_url total_courts]
        ), status: :ok
      end

      def show
        @sports_complex = SportsComplex.find(params[:id])
        render json: @sports_complex.as_json(
          only: %i[id name address city],
          methods: %i[cover_photo_url total_courts]
        ), status: :ok
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Complejo deportivo no encontrado" }, status: :not_found
      end
    end
  end
end
