multiplier = court.multiplier_for(date, slot.start_time, slot.end_time)
final_price = court.calculate_price(date, slot.start_time, slot.end_time)
available = court.available?(date, slot.start_time, slot.end_time)

json.id slot.id
json.day_of_week slot.day_of_week
json.day_name slot.day_name
json.start_time slot.formatted_start_time
json.end_time slot.formatted_end_time
json.time_range slot.formatted_time_range
json.duration_in_hours slot.duration_in_hours
json.pricing do
  json.base_price court.base_price.to_f
  json.multiplier multiplier.to_f
  json.final_price final_price.to_f
end
json.available available
