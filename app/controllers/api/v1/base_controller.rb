module Api
  module V1
    class BaseController < ActionController::API
      before_action :authenticate_api_user!

      attr_reader :current_user

      private

      def authenticate_api_user!
        token = extract_token_from_header
        decoded = JsonWebToken.decode(token) if token

        if decoded && (@current_user = User.find_by(id: decoded[:user_id]))
          # Autenticación exitosa: @current_user queda disponible para las acciones hijas
        else
          render json: { error: "No autorizado. Token inválido o ausente." }, status: :unauthorized
        end
      end

      def extract_token_from_header
        header = request.headers["Authorization"]
        return nil unless header.present?

        # Soporta el formato estándar "Bearer <token>" o el token enviado solo
        header.split(" ").last
      end
    end
  end
end
