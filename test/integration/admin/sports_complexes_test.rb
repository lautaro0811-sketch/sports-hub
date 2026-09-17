require "test_helper"

class Admin::SportsComplexesTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(
      name: "Admin User",
      email: "admin_sc_test@sportshub.com",
      password: "password123",
      role: :admin
    )
    @scheme = PricingScheme.create!(name: "Tarifa SC Test", description: "Tarifa para test")

    post login_path, params: { email: @admin.email, password: "password123" }
    follow_redirect!
  end

  test "crea un complejo deportivo con esquema tarifario predeterminado" do
    assert_difference("SportsComplex.count", 1) do
      post admin_sports_complexes_path, params: {
        sports_complex: {
          name: "Complejo Nuevo Test",
          address: "Calle 10 y 50",
          city: "La Plata",
          phone: "2214445566",
          default_pricing_scheme_id: @scheme.id
        }
      }
    end

    assert_redirected_to admin_sports_complexes_path
    follow_redirect!
    assert_response :success

    created = SportsComplex.find_by!(name: "Complejo Nuevo Test")
    assert_equal @scheme.id, created.default_pricing_scheme_id
    assert_equal @scheme, created.default_pricing_scheme
  end

  test "actualiza un complejo deportivo y su esquema predeterminado" do
    complex = SportsComplex.create!(
      name: "Complejo a Editar",
      address: "Calle 1",
      city: "La Plata",
      phone: "2211112222"
    )

    patch admin_sports_complex_path(complex), params: {
      sports_complex: {
        name: "Complejo Editado",
        default_pricing_scheme_id: @scheme.id
      }
    }

    assert_redirected_to admin_sports_complexes_path
    complex.reload
    assert_equal "Complejo Editado", complex.name
    assert_equal @scheme.id, complex.default_pricing_scheme_id
  end
end
