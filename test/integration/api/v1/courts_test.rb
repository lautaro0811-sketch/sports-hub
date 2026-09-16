require "test_helper"

class Api::V1::CourtsTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)

    @sport = Sport.find_or_create_by!(name: "Fútbol")
    @complex = SportsComplex.first || SportsComplex.create!(name: "Complejo Test", address: "Calle 123")
    @court = @complex.courts.first || @complex.courts.create!(name: "Cancha 1", surface_type: "Césped", sport: @sport, base_price: 1000)

    @token = JsonWebToken.encode(user_id: @user.id)
    @headers = { "Authorization" => "Bearer #{@token}" }
  end

  test "debe listar las canchas de un complejo" do
    get api_v1_sports_complex_courts_url(@complex), headers: @headers

    assert_response :success
    assert_kind_of Array, response.parsed_body
  end

  test "debe mostrar los detalles de una cancha especifica" do
    get api_v1_sports_complex_court_url(@complex, @court), headers: @headers

    assert_response :success
    assert_equal @court.id, response.parsed_body["id"]
    assert_equal @court.name, response.parsed_body["name"]
  end
end
