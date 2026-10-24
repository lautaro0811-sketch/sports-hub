# frozen_string_literal: true

require "test_helper"

class Api::V1::SportsTest < ActionDispatch::IntegrationTest
  fixtures []

  setup do
    @sport_futbol = Sport.find_or_create_by!(name: "Fútbol")
    @sport_padel = Sport.find_or_create_by!(name: "Pádel")
  end

  test "lista deportes de forma publica sin requerir token" do
    get api_v1_sports_url

    assert_response :ok
    body = response.parsed_body
    assert_kind_of Array, body
    names = body.map { |s| s["name"] }
    assert_includes names, "Fútbol"
    assert_includes names, "Pádel"
    assert body.first.key?("courts_count")
  end
end

