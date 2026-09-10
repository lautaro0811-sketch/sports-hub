module Admin
  class BaseController < ApplicationController
    before_action :require_admin!

    layout "admin"

    private

    def require_admin!
      if current_user.nil?
        redirect_to login_path, alert: "Debes iniciar sesión para acceder al panel."
      elsif current_admin_user.nil?
        redirect_to login_path, alert: "Acceso denegado: se requieren permisos de administrador."
      end
    end
  end
end
