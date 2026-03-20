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

data_path = File.join(Dir.pwd, "process_models", dataset, "cpee_xml")
puts data_path
Dir.glob(File.join(data_path, "*.xml")).each do |f|
  puts f
  file_name = File.basename(f, ".xml")
  if !Dir.exist?(File.join(Dir.pwd, "iterations", deterministic ? "det_#{llm}" : llm, dataset, file_name))
    # create directories to save data
    # llm/dataset/name/type/
    text_path = File.join(Dir.pwd, "iterations", deterministic ? "det_#{llm}" : llm, dataset, file_name, "process_descriptions")
    model_path = File.join(Dir.pwd, "iterations", deterministic ? "det_#{llm}" : llm, dataset, file_name, "process_models")
    mermaid_path = File.join(Dir.pwd, "iterations", deterministic ? "det_#{llm}" : llm, dataset, file_name, "mermaids")
    FileUtils.mkdir_p(text_path)
    FileUtils.mkdir_p(model_path)
    FileUtils.mkdir_p(mermaid_path)

    iterations.times do |i|
      puts "input for #{i} is : #{f}"

      begin
        #cpee to text
        if deterministic
          process_description = cpee_to_text_no_llm(f)
        else
          process_description = cpee_to_text_llm(f,llm_model)
        end

        #write description to file
        File.write(File.join(text_path,"#{i}.txt"),process_description)

        # text to cpee
        mermaid, process_model = text_to_cpee_llm(process_description,llm_model)
        File.write(File.join(mermaid_path,"#{i+1}.xml"),mermaid)
        if check_children(process_model)
          #write model to file
          File.write(File.join(model_path,"#{i+1}.xml"),process_model)
          #input for next round
          f = File.join(model_path,"#{i+1}.xml")
        else
          raise Exception.new "Model at iteration #{i} is empty. Stop!!!!"
        end
      rescue Exception => e
        puts "Function failed on #{file_name} at iteration #{i}!!!!!!. \n See #{e} for more details."
        break
      end
    end
  else
    puts "already done"
  end
end
