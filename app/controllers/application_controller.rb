class ApplicationController < ActionController::Base
  helper_method :current_user, :current_admin_user, :current_customer, :logged_in?

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def current_admin_user
    @current_admin_user ||= current_user if current_user&.admin?
  end

  def current_customer
    @current_customer ||= current_user if current_user&.client?
  end

  def logged_in?
    current_user.present?
  end

  def authenticate_user!
    return if logged_in?

    redirect_to login_path, alert: "Debes iniciar sesión para continuar."
  end
end
