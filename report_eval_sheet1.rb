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
  opt.banner = "Usage:\n#{opt.summary_indent}#{File.basename($0)} LLM (-d) \n"
  opt.on("Options:")
  opt.on("--help", "-h", "This text") { puts opt; exit }
  opt.on("--deterministic", "-d", "Deterministic text generation") { deterministic = true }
  opt.on("")
  opt.on(wrap("[LLM]","selecte llm"))
  opt.parse!
}

if ARGV.length != 1
  puts ARGV.options
  exit
else
  llm = ARGV[0]
end

require 'roo'

data_path = File.join(Dir.pwd, "evaluation")
files = Dir.glob(File.join(data_path, "*.xlsx"))
if llm == "all"
  llm = ""
else
  files.select! do |f|
    deterministic ? File.basename(f).start_with?("det_") : !File.basename(f).start_with?("det_")
  end
end

overview = []
files.each do |file|
  puts "Processing #{file}"
  if file.include?(llm)
    xlsx = Roo::Excelx.new(file)
    total_rows = 0
    data = xlsx.each_row_streaming.filter_map do |row|
      values = row.map(&:value)
      total_rows += 1
      values if values[1] == 10   # column 2 (index 1)
    end
    overview << [File.basename(file),total_rows, data.length, data.length.to_f/total_rows]
  end
end

pp overview
