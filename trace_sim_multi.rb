#!/usr/bin/ruby
# encoding: UTF-8

require_relative '../cpee-transformation/lib/cpee/transformation/transformer' rescue nil
require_relative '../cpee-transformation/lib/cpee/transformation/cpee' rescue nil

require 'rubygems'
require "damerau-levenshtein"
require 'rag_embeddings'
require 'daru'
require 'hungarian_algorithm'
require 'hungarian_algorithm_c'

EMBED_CACHE = {}

def embed_cached(text)
  EMBED_CACHE[text] ||= begin
    emb = RagEmbeddings.embed(text, model: "mxbai-embed-large")
    RagEmbeddings::Embedding.from_array(emb)
  end
end

def text_similarity(string1, string2)
  obj1 = embed_cached(string1)
  obj2 = embed_cached(string2)
  return obj1.cosine_similarity(obj2)
end


DIST_CACHE = {}

def text_distance_cached(s, l)
  key = [s, l]
  DIST_CACHE[key] ||= DamerauLevenshtein.array_distance(s, l)
end

def process_model(path)
  Timeout.timeout(60) do
    model = CPEE::Transformation::Source::CPEE.new(File.read(path))
    trans = CPEE::Transformation::Transformer.new(model)
    traces = trans.build_traces
    all_elements = trans.instance_variable_get(:@source).instance_variable_get(:@graph).instance_variable_get(:@nodes)
    tasks = all_elements.select{|id, node| node.type == :task}.to_h{|id, node| [id, node.label]}
    return traces, tasks
  end
rescue Timeout::Error => e
  pp "model is impossible to parse. #{path}"
  raise e
end

def create_sim_matrix(short,long)
  pp "similarity"
  sim_matrix = []
  short.each do |fid,flab|
    temp = []
    long.each do |lid,llab|
      temp << text_similarity(flab, llab)
    end
    sim_matrix << temp
  end
  return sim_matrix
end

def create_lev_matrix(nshort,nlong)
  lev_matrix = []
  nshort.each do |s|
    temp = []
    nlong.each do |l|
      #pp "#{s} x #{l}"
      temp << text_distance_cached(s,l)
      #pp  text_distance_cached(s,l)
    end
    lev_matrix << temp
  end
  return lev_matrix
end

def make_square_matrix(omatrix, dummy_value = 0)
  matrix = omatrix.map(&:dup)
  # Number of rows and columns
  rows = matrix.length
  cols = matrix[0].length

  # Pad with dummy rows if rows < cols
  if rows < cols
    (cols - rows).times { matrix << Array.new(cols, dummy_value) }
  elsif rows > cols
    diff = rows - cols
    matrix.each { |row| row.concat(Array.new(diff, dummy_value)) }
  end
  return matrix
end

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

def get_trace_similarity(first_path,last_path)
  begin
    ftraces, ftasks = process_model(first_path)
    ltraces, ltasks = process_model(last_path)
    ftraces = ftraces.uniq
    ltraces = ltraces.uniq
  rescue Timeout::Error => e
    pp e
    return "failed", "failed"
  end

  if ftasks.length == 0 || ltasks.length == 0
    return "failed", "failed"
  end


  pp "-----------------------------------------------------tasks:  #{ftasks.length}, #{ltasks.length}"

  if ftasks.length != ltasks.length
    pp "tasks:  #{ftasks.length}, #{ltasks.length}"
    return false
  end

  orig_sim_matrix = create_sim_matrix(ftasks,ltasks)
  pp "Calsulate task distance"

  sim_matrix = make_square_matrix(orig_sim_matrix)
  #only for print
  df = Daru::DataFrame.rows(orig_sim_matrix)
  pp "test"
  pp df
  #for reverse hungarian
  max_val = sim_matrix.flatten.max
  cost = sim_matrix.map { |row| row.map { |v| max_val - v } }
  begin
    hung_output = HungarianAlgorithmC.find_pairings(cost)
  rescue SystemStackError => e
    return "failed", "failed"
  end

  task_pairs = hung_output.to_h
  pp task_pairs
  sum = 0
  task_pairs.each do |t|
    begin
      val = df.row[t[0]][t[1]]
      if val > 0.7
        sum = sum + val
      else
        task_pairs[t[0]] = "XXX"
      end
    rescue
      #do nothing
    end
  end
  task_sim = sum.to_f/[ftasks.length,ltasks.length].max
  pp task_pairs

  new_ftraces = []
  ftraces.each do |t|
    ids = t.select{ |el| el.type == :task }.map{ |el| el.id}
    trace = []
    ids.each do |id|
      ind = ftasks.keys.index(id)
      trace << task_pairs.keys.index(ind)
    end
    new_ftraces << trace
  end
  new_ftraces = new_ftraces.uniq

  new_ltraces = []
  ltraces.each do |t|
    ids = t.select{ |el| el.type == :task }.map{ |el| el.id}
    trace = []
    ids.each do |id|
      ind = ltasks.keys.index(id)
      temp = task_pairs.values.index(ind)
      if temp.nil?
        temp = ind + ltasks.length
      end
      trace << temp
    end
    new_ltraces << trace
  end
  new_ltraces = new_ltraces.uniq

  pp "==========+++++++++++++++++========================== Traces"
  pp new_ftraces.length, new_ltraces.length
  if new_ftraces.length != new_ltraces.length
    return false
  end
  pp "calculate levelnstein distance between traces"

  lev_matrix = create_lev_matrix(new_ftraces,new_ltraces)
  square_lev_matrix = make_square_matrix(lev_matrix)

  df = Daru::DataFrame.rows(lev_matrix)
  pp df

  begin
    hung_output = HungarianAlgorithmC.find_pairings(square_lev_matrix)
  rescue SystemStackError => e
    return task_sim, "failed"
  end

  trace_pairs =  hung_output.to_h
  sum = 0
  trace_pairs.each do |s,l|
    begin
      val =  df.row[s][l.to_i]
      maxi = [new_ftraces[s].length, new_ltraces[l.to_i].length].max
      percent = 1 - (val.to_f/maxi)
      sum = sum + percent
    rescue
      #do nothing
    end
  end
  pp sum
  trace_sim = sum/[lev_matrix.length, lev_matrix[0].length].max

  pp "SIMILARITY --------------------------------------------------------"
  pp trace_sim
  if trace_sim != 1
    return false
  else
    return true
  end
end
