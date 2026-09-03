class Court < ApplicationRecord
  belongs_to :sports_complex
  belongs_to :sport
  has_many :time_slots, dependent: :destroy
  has_many :reservations, dependent: :destroy
  has_one_attached :image

  validates :name, :surface_type, presence: true

  scope :active, -> { where(is_active: true) }
  scope :by_sport, ->(sport_id) { where(sport_id: sport_id) if sport_id.present? }

  def available?(date, start_time, end_time)
    reservations.where(reservation_date: date)
                .where.not(status: :cancelled)
                .where("start_time < ? AND end_time > ?", end_time, start_time)
                .none?
  end
end