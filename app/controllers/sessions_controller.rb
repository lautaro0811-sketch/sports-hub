class SessionsController < ApplicationController
  def new
    redirect_to admin_root_path if current_admin_user
  end

  def create
    raw_email = params[:email] || params.dig(:session, :email) || params.dig(:user, :email)
    raw_password = params[:password] || params.dig(:session, :password) || params.dig(:user, :password)

    email = raw_email.to_s.strip.downcase
    password = raw_password.to_s

    user = User.find_by("LOWER(email) = ?", email)

    if user&.authenticate(password)
      session[:user_id] = user.id
      handle_post_login_redirect(user)
    else
      flash.now[:alert] = "Credenciales inválidas"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session[:user_id] = nil
    redirect_to login_path, notice: "Sesión cerrada correctamente."
  end

  private

  def handle_post_login_redirect(user)
    if user.admin?
      redirect_to admin_root_path, notice: "Bienvenido al panel de administración, #{user.name}."
    else
      redirect_to login_path, notice: "Sesión iniciada correctamente, #{user.name}."
    end
  end
end
