json.date @date.to_s
json.day_of_week @date.wday
json.courts @courts do |court|
  json.partial! "api/v1/courts/court", court: court, date: @date
end

