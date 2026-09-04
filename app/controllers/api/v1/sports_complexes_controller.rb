module Api
  module V1
    class SportsComplexesController < BaseController
      def index
        @complexes = SportsComplex.with_attached_cover_photo.all

        render json: @complexes.map { |complex| serialize_complex(complex) }
      end

      def show
        @complex = SportsComplex.find(params[:id])

        render json: serialize_complex(@complex, detailed: true)
      end

      private

      def serialize_complex(complex, detailed: false)
        data = {
          id: complex.id,
          name: complex.name,
          address: complex.address,
          city: complex.city,
          phone: complex.phone,
          cover_photo_url: complex.cover_photo.attached? ? Rails.application.routes.url_helpers.rails_blob_url(complex.cover_photo, only_path: true) : nil
        }

        if detailed
          data[:courts] = complex.courts.where(is_active: true).includes(:sport).map do |court|
            {
              id: court.id,
              name: court.name,
              sport: court.sport.name,
              surface_type: court.surface_type
            }
          end
        end

        data
      end
    end
  end
end