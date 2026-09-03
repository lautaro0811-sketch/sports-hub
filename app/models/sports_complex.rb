class SportsComplex < ApplicationRecord
    has_many :courts, dependent: :destroy
    has_one_attached :cover_photo

    validates :name, :address, :city, presence: true

    def total_courts
        courts.count
    end

    def active_courts
        courts.where(is_active: true)
    end
end
