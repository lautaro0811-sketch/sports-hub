module Api
  module V1
    class CourtsController < BaseController
      def index
        @courts = Court.where(is_active: true).includes(:sports_complex, :sport)

        @courts = @courts.where(sports_complex_id: params[:sports_complex_id]) if params[:sports_complex_id].present?
        @courts = @courts.where(sport_id: params[:sport_id]) if params[:sport_id].present?

        render json: @courts.map { |court| serialize_court(court) }
      end

      def show
        @court = Court.includes(:sports_complex, :sport, :time_slots).find(params[:id])

        render json: serialize_court(@court, detailed: true)
      end

      private

      def serialize_court(court, detailed: false)
        data = {
          id: court.id,
          name: court.name,
          surface_type: court.surface_type,
          sport: {
            id: court.sport.id,
            name: court.sport.name
          },
          sports_complex: {
            id: court.sports_complex.id,
            name: court.sports_complex.name,
            city: court.sports_complex.city
          }
        }

        if detailed
          data[:time_slots] = court.time_slots.order(:day_of_week, :start_time).map do |slot|
            {
              id: slot.id,
              day_of_week: slot.day_of_week,
              start_time: slot.start_time.strftime("%H:%M"),
              end_time: slot.end_time.strftime("%H:%M"),
              price: slot.price.to_f
            }
          end
        end

        data
      end
    end
  end
end
