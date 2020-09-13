puts "EventManager initialized!"

# using standard Ruby to parse
# small_file = File.exists?(small_file_path) ?
#   File.read(small_file_path) :
#   puts("file not found '#{small_file_path}'")

# small_file = File.exists?(small_file_path) ?
#   File.readlines(small_file_path) :
#   puts("file not found '#{small_file_path}'")

# small_file.each_with_index do |line, i|
#   columns = line.split(",")
#   next if i == 0
#   puts "#{columns[2]} #{columns[3]}"
# end

# using CSV addin
require "csv"
require "google/apis/civicinfo_v2"
require "erb"
require "date"

def create_date_object(date_time)
  date_time = DateTime.strptime(date_time, "%m/%d/%y %H:%M")
end

def week_day(date)
  case date.wday
  when 0
    return "Sunday"
  when 1
    return "Monday"
  when 2
    return "Tuesday"
  when 3
    return "Wednesday"
  when 4
    return "Thursday"
  when 5
    return "Friday"
  when 6
    return "Saturday"
  end
end

def array_count(array)
  count_hash = array.each_with_object(Hash.new(0)) { |word, acc| acc[word] += 1 }
  count_hash = count_hash.sort_by { |k, v| -v }.to_h()
  return count_hash
end

def hour_from_datetime(date_time)
  return date_time.hour
end

def clean_phone_number(phone)
  phone = phone.to_s.gsub(/[\(\)\.\-\s]/, "")
  if phone.length < 10
    phone = "0000000000"
  elsif phone.length == 11
    if phone[0] == "1"
      phone = phone[1...phone.length]
    else
      phone = "0000000000"
    end
  elsif phone.length > 11
    phone = "0000000000"
  end
  return phone
end

def clean_zipcode(zipcode)
  return zipcode.to_s.rjust(5, "0")[0..4]
end

def legislators_by_zipcode(zipcode)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = "AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw"

  begin
    legislators = civic_info.representative_info_by_address(
      address: zipcode,
      levels: "country",
      roles: ["legislatorUpperBody", "legislatorLowerBody"],
    ).officials
  rescue
    return "You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials"
  end
end

def save_thank_you_letter(id, letter)
  Dir.mkdir("output") unless Dir.exists?("output")
  filename = "output/thanks_#{id}.html"
  File.open(filename, "w") do |file|
    file.puts letter
  end
end

small_file_path = "event_attendees.csv"
template_letter = File.read "form_letter.erb"
erb_template = ERB.new template_letter
total_dates = []
total_days = []

contents = CSV.open(small_file_path,
                    headers: true,
                    header_converters: :symbol)

contents.each do |row|
  id = row[0]
  first_name, last_name, zipcode, phone_number, reg_date =
    row[:first_name],
    row[:last_name],
    clean_zipcode(row[:zipcode]),
    row[:homephone],
    row[:regdate]

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)

  puts clean_phone_number(phone_number)
  reg_date = create_date_object(reg_date)
  total_dates.push(hour_from_datetime(reg_date))
  total_days.push(week_day(reg_date))
end

puts array_count(total_dates)
puts array_count(total_days)
