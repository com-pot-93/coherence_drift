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
  s = ARGV.options.summary_indent + s1 + ' ' * (indent - s1.length - ARGV.options.summary_indent.length) + s2
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

require_relative 'all_functions' rescue nil
require_relative 'trace_sim_welements'

deterministic = false

ARGV.options { |opt|
  opt.summary_indent = ' ' * 2
  opt.summary_width = 18
  opt.banner = "Usage:\n#{opt.summary_indent}#{File.basename($0)} -d DATASET (-l LLM)\n"
  opt.on("Options:")
  opt.on("--help", "-h", "This text") { puts opt; exit }
  opt.on("--deterministic", "-d", "Deterministic text generation") { deterministic = true }
  opt.on("")
  opt.on(wrap("[DATASET]","selected dataset"))
  opt.on(wrap("[LLM]","selecte llm"))
  opt.parse!
}

if ARGV.length != 2
  puts ARGV.options
  exit
else
  dataset = ARGV[0]
  llm = ARGV[1]
  if dataset.nil?
    puts ARGV.options
    exit
  end
end

iterations = 10

if llm == "gemini"
  llm_model = "gemini-2.0-flash"
elsif llm == "gpt"
  llm_model = "gpt-4.1"
end

results = []
data_path = File.join(Dir.pwd, "process_models", dataset, "cpee_xml")
puts data_path
Dir.glob(File.join(data_path, "*.xml")).each do |f|
  pp "----------------***********--------------------"
  pp f
  file_name = File.basename(f, ".xml")
  if Dir.exist?(File.join(Dir.pwd, "iterations", deterministic ? "det_#{llm}" : llm, dataset, file_name))
    #origin_path = File.join(data_path, file_name + ".xml")
    models_path = File.join(Dir.pwd, "iterations", deterministic ? "det_#{llm}" : llm, dataset, file_name, "process_models")
    count = Dir.glob("#{models_path}/**/*").count { |f| File.file?(f) }
    if count != 0
      last_path = File.join(models_path, "#{count}.xml")
      pp "=====================similarity"
      if llm == "gpt" && !deterministic && (f.include?("M_j03_2") || f.include?("R_j01_5"))
        task_sim, trace_sim = "failed", "failed"
      else
        task_sim, trace_sim = get_trace_similarity(f,last_path)
      end
      pp "#{count}, #{task_sim}, #{trace_sim}"
      results << [file_name,count,task_sim,trace_sim]
    else
      results << [file_name,count,0,0]
    end
  end
end
pp results


require "caxlsx"

Axlsx::Package.new.tap do |p|
  p.workbook.add_worksheet { |s| results.each { |r| s.add_row(r) } }
  output_file = deterministic ? "det_#{llm}_#{dataset}.xlsx" : "#{llm}_#{dataset}.xlsx"
  p.serialize(File.join(Dir.pwd,"evaluation",output_file))
end
