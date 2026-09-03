class Court < ApplicationRecord
  belongs_to :sports_complex
  belongs_to :sport
end
