#!/usr/bin/ruby
# encoding: UTF-8
#
# This file is part of cpee-transformation.
#
# cpee-transformation is free software: you can redistribute it and/or modify it under the terms
# of the GNU Lesser General Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
#
# cpee-transformation is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
# PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License along with
# cpee-transformation (file COPYING in the main directory).  If not, see
# <http://www.gnu.org/licenses/>.

def wrap(s1, s2, width=78, indent=ARGV.options.summary_width + 3)
  lines = []
  s = ARGV.options.summary_indent + s1 + ' ' * (indent - s1.length - ARGV.options.summary_indent.length)
  line, s = s[0..indent-2], s[indent..-1]
  s.split(/\n/).each do |ss|
    ss.split(/[ \t]+/).each do |word|
      if line.size + word.size >= width
        lines << line
        line = (" " * (indent)) + word
      else
        line << " " << word
      end
    end
    lines << line if line
    line = (" " * (indent-1))
  end
  return lines.join("\n")
end

require 'optparse'

deterministic = false

ARGV.options { |opt|
  opt.summary_indent = ' ' * 2
  opt.summary_width = 18
  opt.banner = "Usage:\n#{opt.summary_indent}#{File.basename($0)} (-d) \n"
  opt.on("Options:")
  opt.on("--help", "-h", "This text") { puts opt; exit }
  opt.on("--deterministic", "-d", "Deterministic text generation") { deterministic = true }
  opt.on("")
  opt.parse!
}


require 'roo'
require 'daru'

data_path = File.join(Dir.pwd, "multi")
files = Dir.glob(File.join(data_path, "*.xlsx"))

files.select! do |f|
  deterministic ? File.basename(f).start_with?("det_") : !File.basename(f).start_with?("det_")
end

overview = []
files.each do |file|
  puts "Processing #{file}"
  xlsx = Roo::Excelx.new(file)
  data = xlsx.each_row_streaming.filter_map do |row|
    values = row.map(&:value)
  end
  df = Daru::DataFrame.rows(data)
  iter = df["1"].to_a
  overview << iter
end

numbers =  overview.flatten
pp numbers

freq = numbers.tally
pp freq


total = freq.values.sum.to_f
percent_hash = freq.transform_values do |v|
  ((v / total) * 100).round(1)
end
puts percent_hash

total = percent_hash.values.sum.to_f
pp total
#require 'gruff'
#
#g = Gruff::Bar.new(400)      # width in pixels
#g.title = "Histogram"
#freq.each { |num, count| g.data(num.to_s, count) }
#filename = deterministic ? "det_hist.png" : "nondet_hist.png"
#g.write(filename)
#puts "Saved #{filename}"


#labels = freq.keys
#values = freq.values
#
#plot = Rubyplot::Bar.new
#plot.title = 'Number Distribution'
#plot.data :Numbers, values
#plot.labels = labels.each_with_index.map { |v,i| [i, v.to_s] }.to_h
#
#plot.write( deterministic ? "det_hist.svg" : "nondet_hist.svg")
#
#puts "Saved histogram_rubyplot.png"
