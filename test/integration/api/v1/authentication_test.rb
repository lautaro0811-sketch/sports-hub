# frozen_string_literal: true

require "test_helper"

class Api::V1::AuthenticationTest < ActionDispatch::IntegrationTest
  fixtures []

  setup do
    @user = User.create!(
      name: "Juan Perez",
      email: "juan@example.com",
      password: "password123",
      role: :client
    )
  end

  test "login con credenciales validas retorna token y datos del usuario" do
    post api_v1_auth_login_url, params: { email: @user.email, password: "password123" }

    assert_response :ok
    body = response.parsed_body
    assert_not_nil body["token"]
    assert_not_nil body["exp"]
    assert_equal @user.id, body["user"]["id"]
    assert_equal @user.name, body["user"]["name"]
    assert_equal @user.email, body["user"]["email"]
    assert_equal "client", body["user"]["role"]
  end

  test "login con password incorrecta retorna 401" do
    post api_v1_auth_login_url, params: { email: @user.email, password: "wrongpassword" }

    assert_response :unauthorized
    assert_equal "Credenciales inválidas", response.parsed_body["error"]
  end

  test "registro con datos validos crea usuario y retorna 201 con token" do
    assert_difference("User.count", 1) do
      post api_v1_auth_register_url, params: {
        name: "Nuevo Cliente",
        email: "nuevo@example.com",
        password: "password123",
        password_confirmation: "password123"
      }
    end

    assert_response :created
    body = response.parsed_body
    assert_not_nil body["token"]
    assert_equal "Nuevo Cliente", body["user"]["name"]
    assert_equal "nuevo@example.com", body["user"]["email"]
    assert_equal "client", body["user"]["role"]

    created_user = User.find_by(email: "nuevo@example.com")
    assert created_user.client?
  end

  test "registro con email duplicado retorna 422 con errores" do
    assert_no_difference("User.count") do
      post api_v1_auth_register_url, params: {
        name: "Otro Juan",
        email: @user.email,
        password: "password123"
      }
    end

    assert_response :unprocessable_entity
    assert_includes response.parsed_body["errors"].join, "Email ya está en uso"
  end

  test "me con token valido retorna los datos del usuario autenticado" do
    token = JsonWebToken.encode(user_id: @user.id)
    get api_v1_auth_me_url, headers: { "Authorization" => "Bearer #{token}" }

    assert_response :ok
    body = response.parsed_body
    assert_equal @user.id, body["user"]["id"]
    assert_equal @user.name, body["user"]["name"]
    assert_equal @user.email, body["user"]["email"]
  end

  test "me sin token retorna 401 unauthorized" do
    get api_v1_auth_me_url

    assert_response :unauthorized
    assert_includes response.parsed_body["error"], "No autorizado"
  end
end

