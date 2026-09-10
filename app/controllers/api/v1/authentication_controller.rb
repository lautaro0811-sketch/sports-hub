module Api
  module V1
    class AuthenticationController < BaseController
      skip_before_action :authenticate_api_user!, only: :login

      def login
        user = User.find_by("LOWER(email) = ?", login_params[:email].to_s.strip.downcase)

        if user&.authenticate(login_params[:password].to_s)
          token = JsonWebToken.encode(user_id: user.id)
          render json: {
            token: token,
            exp: 24.hours.from_now.to_i,
            user: {
              id: user.id,
              name: user.name,
              email: user.email,
              role: user.role
            }
          }, status: :ok
        else
          render json: { error: "Credenciales inválidas" }, status: :unauthorized
        end
      end

      private

      def login_params
        params.permit(:email, :password)
      end
    end
  end
end