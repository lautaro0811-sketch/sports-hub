json.id court.id
json.name court.name
json.surface_type court.surface_type
json.base_price court.base_price.to_f
json.is_active court.is_active
json.pricing_scheme_name court.pricing_scheme_name
json.image_url court.image_url
if court.sport.present?
  json.sport do
    json.id court.sport.id
    json.name court.sport.name
  end
else
  json.sport nil
end

if court.sports_complex.present?
  json.sports_complex do
    json.id court.sports_complex.id
    json.name court.sports_complex.name
    json.address court.sports_complex.address
    json.city court.sports_complex.city
    json.cover_photo_url court.sports_complex.cover_photo_url
  end
else
  json.sports_complex nil
end

slots_for_day = court.time_slots.select { |slot| slot.day_of_week == date.wday }
                                 .sort_by(&:start_time)

json.time_slots slots_for_day do |slot|
  json.partial! "api/v1/courts/time_slot", slot: slot, court: court, date: date
end
