require 'csv'
require 'roo'


def create_svg(data,color,file_name)
# SVG setup
  width = 500
  height = 300
  padding = 40

# Function to scale x (0..9) to pixel width
  def scale_x(i, width, padding)
    padding + i * (width - 2*padding)/9.0
  end

# Function to scale y (0..1) to pixel height (inverted because SVG y=0 is top)
  def scale_y(v, height, padding)
    height - padding - v*(height - 2*padding)
  end

# Start SVG string
  svg = %Q(<svg width="#{width}" height="#{height}" xmlns="http://www.w3.org/2000/svg">\n)

# Draw axes
  svg << %Q(<line x1="#{padding}" y1="#{height-padding}" x2="#{width-padding}" y2="#{height-padding}" stroke="black"/>\n)
  svg << %Q(<line x1="#{padding}" y1="#{padding}" x2="#{padding}" y2="#{height-padding}" stroke="black"/>\n)

# Draw lines for each row
#colors = ["red", "blue", "green", "orange", "purple"]
  colors = [color]
  data.each_with_index do |values, idx|
    pp values
    if values.all? { |v| Float(v) rescue false }
      drift = values.map { |v| 1 - v }
      points = drift.each_with_index.map { |v,i| "#{scale_x(i,width,padding)},#{scale_y(v,height,padding)}" }.join(" ")
      svg << %Q(<polyline fill="none" stroke="#{colors[idx%colors.size]}" stroke-width="2" points="#{points}"/>\n)
    end
  end

# Close SVG
  svg << "</svg>"

# Save to file
  File.write("./all_svg/#{File.basename(file_name)}.svg", svg)
  puts "SVG linechart saved as linechart.svg"
end


data_path = File.join(Dir.pwd, "all_sim")
files = Dir.glob(File.join(data_path, "*.xlsx"))
colors = ["red", "blue", "green", "orange", "purple","teal","red", "blue", "green", "orange", "purple","teal"]

pp files
files.each_with_index do |file,c|
  overview = []
  puts "Processing #{file}"
  xlsx = Roo::Excelx.new(file)
  data = xlsx.each_row_streaming.filter_map do |row|
    values = row.map(&:value)
    next if values.empty?
    overview << values[1..10]
  end
  create_svg(overview,colors[c],file)
end
pp "end"

