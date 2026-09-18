class Sport < ApplicationRecord
  has_many :courts, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true

  def courts_count
    courts.count
  end
end

#comentario de prueba