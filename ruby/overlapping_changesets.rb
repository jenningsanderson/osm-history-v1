'''
This script identifies nodes that appear in multiple changesets in which the changesets
overlap eachother -- that is, changesets exist in which one is opened before another is closed.
'''
require 'mongo'
require 'rsruby'

require_relative 'user_changesets_sampled'

TIMES = {:haiti=>{
                :start=>Time.new(2010,1,12),
                :end  =>Time.new(2010,2,12)},

              :philippines=>{
                :start=>Time.new(2013,11,8),
                :end  =>Time.new(2013,12,8)}
             }


####################################################
############   Implicit Runtime    #################
####################################################

event = ARGV[0]
event ||= 'haiti'

#Connect to Mongo
CONN = Mongo::MongoClient.new('epic-analytics.cs.colorado.edu', 27018)
DB = CONN[event]
COLL = DB['changesets']

results = COLL.find({'created_at' => {'$gt'=>TIMES[event.to_sym][:start],'$lt'=>TIMES[event.to_sym][:end]}},
                    {:limit=>nil, :fields=>['id','nodes', 'created_at', 'closed_at']})

num_results = results.count()
num_conflicts = 0
puts "Found #{num_results} changesets in the disaster window"


#Shift & sort the results from Mongo
changesets_by_node = {}
changeset_times = {}

results.each do |changeset|
  changeset_times[changeset['id']] = {:created_at=>changeset['created_at'], :closed_at=>changeset['closed_at']}
  unless changeset['nodes'].nil?
    changeset['nodes'].each do |node|
      node_id = node.to_i
      changesets_by_node[node_id] ||= [] #Define an array if it doesn't already exist
      changesets_by_node[node_id] << changeset['id']
    end
  end
end

#Pull out nodes that don't appear in more than 1 changeset
changesets_by_node.reject! { |k,v| v.size < 2 }

#How many nodes appear in these changesets?
nodes_in_multiple_changesets = changesets_by_node.keys.length

puts "#{nodes_in_multiple_changesets} nodes with more than 1 changeset"


#Now identify the nodes that overlap
conflict_nodes = []
changesets_by_node.sort_by{ |k,v| v.size}.each do |node, changesets|
  
  #Sort the changesets by start time, then create an array of open, close, open, close, etc.
  sorted_time = []
  changesets.sort_by{|changeset| changeset_times[changeset][:created_at]}.each do |set|
    sorted_time << changeset_times[set][:created_at] << changeset_times[set][:closed_at]
  end

  #Now sort the array of open, close, open, close, if it doesn't equal the previous, then one
  #changeset on a node is opened before another is closed
  unless (sorted_time == sorted_time.sort)
    num_conflicts += 1
    conflict_nodes << node
  end
end

puts "Conflicts: #{num_conflicts}"
puts "Percentage of nodes: #{num_conflicts.to_f / nodes_in_multiple_changesets*100}"

#r = RSRuby.instance


