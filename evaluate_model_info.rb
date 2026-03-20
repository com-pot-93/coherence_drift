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
  opt.banner = "Usage:\n#{opt.summary_indent}#{File.basename($0)} dataset LLM (-d) \n"
  opt.on("Options:")
  opt.on("--help", "-h", "This text") { puts opt; exit }
  opt.on("--deterministic", "-d", "Deterministic text generation") { deterministic = true }
  opt.on("")
  opt.on(wrap("[dataset]","selecte llm"))
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

require_relative '../cpee-transformation/lib/cpee/transformation/transformer' rescue nil
require_relative '../cpee-transformation/lib/cpee/transformation/cpee' rescue nil

def get_trace_length(path)
  model = CPEE::Transformation::Source::CPEE.new(File.read(path))
  trans = CPEE::Transformation::Transformer.new(model)
  traces = trans.build_traces
  traces = traces.uniq
  return traces.length
end


require 'roo'
require 'daru'
require_relative 'all_functions'

file = File.join(Dir.pwd, "evaluation", deterministic ? "det_#{llm}_#{dataset}.xlsx" : "#{llm}_#{dataset}.xlsx")

overview = []
puts "Processing #{file}"

xlsx = Roo::Excelx.new(file)
data = xlsx.each_row_streaming.filter_map do |row|
  values = row.map(&:value)
  values if values[1] == 10  && (values[3].to_s != "failed" && values[3].to_s.strip.downcase != "nan")
end
df = Daru::DataFrame.rows(data)
files_to_process =  df["0"].to_a

files_to_process.each do |f|
  orig_path = File.join(Dir.pwd, "process_models", dataset, "cpee_xml","#{f}.xml")
  models_path = File.join(Dir.pwd, "iterations", deterministic ? "det_#{llm}" : llm, dataset, f, "process_models")
  model_path = File.join(models_path,"10.xml")

  info_1 = get_model_info(orig_path)
  info_2 = get_model_info(model_path)
  traces_1 = get_trace_length(orig_path)
  traces_2 = get_trace_length(model_path)
  overview << [File.basename(f),info_1,traces_1,info_2,traces_2].flatten
end

df_info = Daru::DataFrame.rows(overview)
df_info.add_vector("ts", df["2"])
df_info.add_vector("trs", df["3"])

require "caxlsx"

Axlsx::Package.new.tap do |p|
  p.workbook.add_worksheet do |s|
    df_info.each_row { |r| s.add_row(r.to_a) }
  end
  output_file = deterministic ? "det_#{llm}_#{dataset}.xlsx" : "#{llm}_#{dataset}.xlsx"
  p.serialize(File.join(Dir.pwd, "model_info", output_file))
end
