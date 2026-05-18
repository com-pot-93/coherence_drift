#!/usr/bin/ruby
# encoding: UTF-8

require_relative '../cpee-transformation/lib/cpee/transformation/transformer' rescue nil
require_relative '../cpee-transformation/lib/cpee/transformation/cpee' rescue nil
require_relative '../cpee-transformation/lib/cpee/transformation/text-df-PO-extended' rescue nil

require 'curb'
require 'json'

require 'net/http/post/multipart'
require 'uri'
require 'stringio'

require 'xml/smart'

def get_model_info(first_path)
  doc = XML::Smart.string(File.read(first_path))
  doc.register_namespace 'd', 'http://cpee.org/ns/description/1.0'
  tasks = doc.find('//d:call').length
  parallels = doc.find('//d:parallel').length
  decisions = doc.find('//d:choose').length
  loops = doc.find('//d:loop').length
  escapes = doc.find('//d:escape').length
  return [tasks,parallels,decisions,loops,escapes]
end

def update_model_info(arr)
  result = arr.each_with_index.map do |val, i|
    if i == 1 || i == 2
      val * 2
    elsif i == arr.length - 1
      val + 2
    else
      val
    end
  end
  return result
end

def check_children(process_model)
  doc = XML::Smart.string(process_model)
  doc.register_namespace 'd', 'http://cpee.org/ns/description/1.0'
  if doc.find('//d:description').first.children.empty?
   return false
  else
    return true
  end
end

def cpee_to_text_no_llm(f)
  begin
    model = CPEE::Transformation::Source::CPEE.new(File.read(f))
    trans = CPEE::Transformation::Transformer.new(model)
    traces = trans.build_traces
    tree = trans.build_tree(false)
    process_description = trans.generate_model(CPEE::Transformation::Target::Text_df_PO_extended)
    return process_description
  rescue Exception => e
    raise e
  end
end

def cpee_to_text_llm(f,llm_model)
  c = Curl::Easy.new("https://autobpmn.ai/llm/text/llm/")
  c.multipart_form_post = true
  c.http_post(
    Curl::PostField.file('rpst_xml', f, 'text/xml'),
    Curl::PostField.content('llm', llm_model)
  )
  begin
    #puts "Status: #{c.response_code}"
    if c.response_code == 200
      data = JSON.parse(c.body_str)
      process_description = data["output_text"]
      return process_description
    else
      raise Exception.new "LLM request failed with #{c.response_code}!!!. \n For more details see: \n #{c.body_str}."
    end
  rescue Exception => e
    raise e
  end
end

def text_to_cpee_llm(description,llm_model)
  #description = File.read(f)
  url = URI.parse("https://autobpmn.ai/llm/")
  req = Net::HTTP::Post::Multipart.new(
    url.path,
    "rpst_xml"   => UploadIO.new("cpee_empty_example", "text/xml", "cpee_empty_example"),
    "user_input" => UploadIO.new(StringIO.new(description), "text/plain", "user_input.txt"),
    "llm"        => UploadIO.new(StringIO.new(llm_model), "text/plain", "llm.txt")
  )
  http = Net::HTTP.new(url.host, url.port)
  http.use_ssl = (url.scheme == "https")
  response = http.request(req)
  begin
    if response.code.to_i == 200
      data = JSON.parse(response.body)
      mermaid = data["output_intermediate"]
      process_model = data["output_cpee"]
      return mermaid, process_model
    else
      raise Exception.new "LLM request failed with #{response.code}!!!. \n For more details see: \n #{response.body}."
    end
  rescue Exception => e
    raise e
  end
end
