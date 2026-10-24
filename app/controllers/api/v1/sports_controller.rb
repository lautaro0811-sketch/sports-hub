# frozen_string_literal: true

module Api
  module V1
    class SportsController < BaseController
      skip_before_action :authenticate_api_user!, only: :index

      def index
        @sports = Sport.order(:name)
        render json: @sports.as_json(only: %i[id name], methods: %i[courts_count]), status: :ok
      end
    end
  end
end
