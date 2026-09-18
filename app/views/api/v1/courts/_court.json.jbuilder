json.id court.id
json.name court.name
json.surface_type court.surface_type
json.base_price court.base_price.to_f
json.is_active court.is_active
json.pricing_scheme_name court.pricing_scheme_name
if court.sport.present?
  json.sport do
    json.id court.sport.id
    json.name court.sport.name
  end
else
  json.sport nil
end

slots_for_day = court.time_slots.select { |slot| slot.day_of_week == date.wday }
                                 .sort_by(&:start_time)

json.time_slots slots_for_day do |slot|
  json.partial! "api/v1/courts/time_slot", slot: slot, court: court, date: date
end
