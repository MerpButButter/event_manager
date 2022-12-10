# rubocop:disable Lint/ConstantResolution

require "date"
require "time"
require "csv"
require "google/apis/civicinfo_v2"
require "erb"

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, "0")[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = "AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw"

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: "country",
      roles: ["legislatorUpperBody", "legislatorLowerBody"]
    ).officials
  rescue StandardError
    "You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials"
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir("output") unless Dir.exist?("output")

  filename = "output/thanks_#{id}.html"

  File.open(filename, "w") do |file|
    file.puts(form_letter)
  end
end

def validate_phonenumber(phonenumber) 
  clean_number = phonenumber.gsub(/\D/, "")
  if clean_number.length.between?(10, 11)
    return "INVALID" if clean_number.length == 11 && clean_number[0] != "1" 
    
    return clean_number[1..-1] if clean_number.length == 11
    
    clean_number 
  else
    "INVALID"
  end
end

def top_visits(array)
  array.tally.sort { |a, b| b[1] <=> a[1] }.to_h
end

puts "EventManager initialized."

contents = CSV.open("event_attendees.csv", headers: true, header_converters: :symbol)

template_letter = File.read("form_letter.erb")
erb_template = ERB.new(template_letter)

hours_visited = []
days_visited = []
contents.each do |row|
  id = row[0]
  phonenumber = validate_phonenumber(row[:homephone])
  regdate = Time.strptime(row[:regdate], "%D %H:%M")
  hours_visited.push(regdate.hour)
  days_visited.push(Date::DAYNAMES[regdate.wday])
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)
end
p top_visits(hours_visited)
p top_visits(days_visited)
# rubocop:enable Lint/ConstantResolution