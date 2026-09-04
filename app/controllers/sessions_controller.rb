class SessionsController < ApplicationController
  def new
    redirect_to admin_root_path if current_user&.admin?
  end

  def create
    raw_email = params[:email] || params.dig(:session, :email) || params.dig(:user, :email)
    raw_password = params[:password] || params.dig(:session, :password) || params.dig(:user, :password)

    email = raw_email.to_s.strip.downcase
    password = raw_password.to_s

    user = User.find_by("LOWER(email) = ?", email)

    if user&.authenticate(password) && user.admin?
      session[:user_id] = user.id
      flash[:notice] = "Bienvenido al panel de administración, #{user.name}."
      redirect_to admin_root_path
    else
      flash.now[:alert] = "Credenciales inválidas o no posee permisos de administrador."
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session[:user_id] = nil
    flash[:notice] = "Sesión cerrada correctamente."
    redirect_to login_path
  end

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end
  helper_method :current_user
end