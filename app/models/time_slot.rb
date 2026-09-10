class TimeSlot < ApplicationRecord
  belongs_to :court

  validates :day_of_week, presence: true, inclusion: { in: 0..6 }
  validates :start_time, :end_time, :price, presence: true
  validates :price, numericality: { greater_than: 0 }
  validate :valid_time_range

  def duration_in_hours
    return 0 unless start_time && end_time

    ((end_time - start_time) / 1.hour).to_f
  end

  private

  def valid_time_range
    return if start_time.blank? || end_time.blank?

    if end_time <= start_time
      errors.add(:end_time, "debe ser posterior a la hora de inicio")
    end
  end
end
