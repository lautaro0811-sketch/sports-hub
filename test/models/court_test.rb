require "test_helper"

class CourtTest < ActiveSupport::TestCase
  fixtures []

  setup do
    @sport = Sport.find_or_create_by!(name: "Fútbol Test")
    @complex = SportsComplex.new(name: "Complejo Test", address: "Calle 123")
    @complex.save(validate: false)

    @court = Court.new(
      name: "Cancha 1",
      surface_type: "Césped sintético",
      sport: @sport,
      sports_complex: @complex
    )
    @court.save(validate: false)
  end

  test "permite adjuntar una imagen a la cancha" do
    # Adjuntamos un archivo en memoria simulado
    @court.image.attach(
      io: StringIO.new("fake-image-content"),
      filename: "cancha.png",
      content_type: "image/png"
    )

    assert @court.image.attached?
  end
end
