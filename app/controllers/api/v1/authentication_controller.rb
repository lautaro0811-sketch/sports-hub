module Api
  module V1
    class AuthenticationController < BaseController
      skip_before_action :authenticate_api_user!, only: %i[login register]

      def login
        user = User.find_by("LOWER(email) = ?", login_params[:email].to_s.strip.downcase)

        if user&.authenticate(login_params[:password].to_s)
          token = JsonWebToken.encode(user_id: user.id)
          render json: {
            token: token,
            exp: 24.hours.from_now.to_i,
            user: user_payload(user)
          }, status: :ok
        else
          render json: { error: "Credenciales inválidas" }, status: :unauthorized
        end
      end

      def register
        user = User.new(register_params)
        user.role = :client

        if user.save
          token = JsonWebToken.encode(user_id: user.id)
          render json: {
            token: token,
            exp: 24.hours.from_now.to_i,
            user: user_payload(user)
          }, status: :created
        else
          render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def me
        render json: { user: user_payload(current_user) }, status: :ok
      end

      private

      def login_params
        params.permit(:email, :password)
      end

      def register_params
        params.permit(:name, :email, :password, :password_confirmation)
      end

      def user_payload(user)
        {
          id: user.id,
          name: user.name,
          email: user.email,
          role: user.role
        }
      end
    end
  end
end
