require 'gruff'

# Example "data frame" as array of arrays
# Each row: [filename, v1..v10]
data_frame = [
  ['file1', 0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1.0],
  ['file2', 0.9,0.8,0.7,0.6,0.5,0.4,0.3,0.2,0.1,0.0]
]

# Create Gruff line chart
g = Gruff::Line.new(800)          # width
g.title = 'Drift Line Chart'
g.theme = Gruff::Themes::PASTEL   # optional theme

# X-axis labels 0..9
g.labels = (0..9).map { |i| [i, i.to_s] }.to_h

# Add each row as a line
data_frame.each do |row|
  filename, *values = row
  drift = values.map { |v| 1 - v }  # transform values to 1 - value
  g.data(filename, drift)
end

# Save chart as PNG
g.write('linechart.png')
puts "Line chart saved as linechart.png"
