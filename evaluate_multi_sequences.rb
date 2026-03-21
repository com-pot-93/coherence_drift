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

if ARGV.length != 2
  puts ARGV.options
  exit
else
  dataset = ARGV[0]
  llm = ARGV[1]
end

require 'roo'
require 'daru'
require_relative 'trace_sim_multi'

iterations = 10
data_path = File.join(Dir.pwd, "evaluation", deterministic ? "det_#{llm}_#{dataset}.xlsx" : "#{llm}_#{dataset}.xlsx")

overview = []
xlsx = Roo::Excelx.new(data_path)
data = xlsx.each_row_streaming.filter_map do |row|
  values = row.map(&:value)
  values if values[1] == 10  && (values[3].to_s != "failed" && values[3].to_s.strip.downcase != "nan")
end

df = Daru::DataFrame.rows(data)
df_filtered = df.where(df["3"].to_a.map { |v| v.to_f != 1 })
files_to_process =  df_filtered["0"].to_a
pp files_to_process.length

files_to_process.each do |f|
  orig_path = File.join(Dir.pwd, "process_models", dataset, "cpee_xml","#{f}.xml")
  models_path = File.join(Dir.pwd, "iterations", deterministic ? "det_#{llm}" : llm, dataset, f, "process_models")
  stop = 0
  iterations.times do |i|
    model_path = File.join(models_path,"#{i+1}.xml")
    pp model_path
    status = get_trace_similarity(orig_path,model_path)
    pp status
    if status == false
      stop = i+1
      break
    end
  end
  overview << [f,stop, stop.to_f/iterations]
end

pp overview

require "caxlsx"

Axlsx::Package.new.tap do |p|
  p.workbook.add_worksheet { |s| overview.each { |r| s.add_row(r) } }
  output_file = deterministic ? "det_#{llm}_#{dataset}.xlsx" : "#{llm}_#{dataset}.xlsx"
  p.serialize(File.join(Dir.pwd,"multi",output_file))
end

