require_relative 'all_functions' rescue nil
require_relative 'trace_sim_threshold'

first = "tests/model1.xml"
last = "tests/model2.xml"

task_sim, trace_sim = get_trace_similarity(first,last)

pp task_sim
pp trace_sim
