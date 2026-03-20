require 'roo'



data_path = File.join(Dir.pwd, "all_sim")
files = Dir.glob(File.join(data_path, "*.xlsx"))


final = []
files.each_with_index do |file,c|
  overview = []
  puts "Processing #{file}"
  xlsx = Roo::Excelx.new(file)
  data = xlsx.each_row_streaming.filter_map do |row|
    values = row.map(&:value)
    next if values.empty?
    overview << values[1..10]
    all_same = values[1..10].uniq.length == 1
    if all_same and values[1..10].uniq[0] == 1
      final << 1
    end
  end
end

pp final
pp final.length
pp "end"

