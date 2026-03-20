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

require 'roo'
require 'daru'

data_path = File.join(Dir.pwd, "evaluation")
files = Dir.glob(File.join(data_path, "*.xlsx"))

files.select! do |f|
  !File.basename(f).start_with?("det_")
end

columns = []
agreement = []
det = []
norm = []
files.each do |file|
  puts "Processing #{file}"
  xlsx = Roo::Excelx.new(file)
  name= File.basename(file)
  other = file.sub(name, "det_#{name}")
  other_xlsx = Roo::Excelx.new(other)
  agree = (1..xlsx.last_row).count do |i|
    xlsx.cell(i,4) == other_xlsx.cell(i,4) && xlsx.cell(i,2) == 10 && xlsx.cell(i,2) == other_xlsx.cell(i,2)
  end
  det_norm = (1..xlsx.last_row).count do |i|
    other_xlsx.cell(i,4).to_f > xlsx.cell(i,4).to_f && xlsx.cell(i,2) == 10 && xlsx.cell(i,2) == other_xlsx.cell(i,2)
  end
  norm_det = (1..xlsx.last_row).count do |i|
    xlsx.cell(i,4).to_f > other_xlsx.cell(i,4).to_f && xlsx.cell(i,2) == 10 && xlsx.cell(i,2) == other_xlsx.cell(i,2)
  end
  columns << File.basename(file)
  agreement << agree
  det << det_norm
  norm << norm_det
end

pp columns
pp agreement
pp det
pp norm
#df = Daru::DataFrame.rows(overview)
#pp df.corr
#
