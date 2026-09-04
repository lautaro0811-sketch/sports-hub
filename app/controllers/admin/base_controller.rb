module Admin
  class BaseController < ApplicationController
    before_action :authenticate_admin!

    layout "admin"

    private

    def authenticate_admin!
      unless current_user&.admin?
        flash[:alert] = "Acceso no autorizado. Debe iniciar sesión como administrador."
        redirect_to login_path
      end
    end

    def current_user
      @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
    end
    helper_method :current_user
  end
end