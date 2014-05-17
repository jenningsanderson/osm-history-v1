'''
This script identifies nodes that appear in multiple changesets in which the changesets
overlap eachother -- that is, changesets exist in which one is opened before another is closed.
'''
require 'mongo'
require 'rsruby'
require 'time'
require 'json'

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
limit = ARGV[1].to_i
event ||= 'haiti'
limit ||= nil

#Connect to Mongo
CONN = Mongo::MongoClient.new('epic-analytics.cs.colorado.edu', 27018)
DB = CONN[event]
COLL = DB['changesets']

results = COLL.find({'created_at' => {'$gt'=>TIMES[event.to_sym][:start],'$lt'=>TIMES[event.to_sym][:end]},
                    'node_count'  => {'$lt'=>10000}},
                    {:limit=>limit, :fields=>['id','nodes', 'created_at', 'closed_at', 'uid']})

#Ignoring time
#results = COLL.find({'node_count' => {'$lt' => 10000}},
#                    {:limit=>limit, :fields=>['id','nodes', 'created_at', 'closed_at']})


num_results = results.count()
num_conflict_nodes = 0
puts "Found #{num_results} changesets in the disaster window"


#Shift & sort the results from Mongo
changesets_by_node = {}
changeset_times = {}

results.each do |changeset|
  changeset_times[changeset['id']] = {:created_at=>changeset['created_at'], :closed_at=>changeset['closed_at'], :user=>changeset['uid']}
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
conflict_nodes = {}
changesets_by_node.sort_by{ |k,v| v.size}.each do |node, changesets|

  changesets.uniq!
  
  #Sort the changesets by start time, then create an array of open, close, open, close, etc.
  sorted_time = []
  sorted_changesets = changesets.sort_by{|changeset| changeset_times[changeset][:created_at]}
  sorted_changesets.each do |set|
    sorted_time << changeset_times[set][:created_at] << changeset_times[set][:closed_at]
  end

  #Now sort the array of open, close, open, close, if it doesn't equal the previous, then one
  #changeset on a node is opened before another is closed
  #unless (sorted_time == sorted_time.sort)
  #  num_conflicts += 1
  #  conflict_nodes << node
  #end

  #Instead of just counting the conflicts, lets look at which changesets actually cause the conflicts
  last_close_time = changeset_times[sorted_changesets[0]][:closed_at]
  prev_set = sorted_changesets[0]
  prev_user = changeset_times[sorted_changesets[0]][:user]
  sorted_changesets[1..-1].each do |this_set|  
    if (changeset_times[this_set][:created_at] < last_close_time) and (prev_user != changeset_times[this_set][:user])
      conflict_nodes[node] ||=[]
      conflict_nodes[node] << [prev_set, this_set]
    end
    last_close_time = changeset_times[this_set][:closed_at]
    prev_set = this_set
  end
  #Instead of just sorting, I want to keep track of them
  #sorted_time.each_cons(4) do |start1,end1,start1,end1|
  #  if


end

puts "Conflicts: #{conflict_nodes.keys.length}"
puts "Percentage of nodes: #{conflict_nodes.keys.length.to_f / nodes_in_multiple_changesets*100}"

#Now visualize these results with R
#First, build a vector of all the times
conflict_days = []
conflict_nodes.values.each do |set| 
   conflict_days << changeset_times[set[0][1]][:created_at].iso8601 #Only grab 1 per conflict
 end
#Start rsruby
r = RSRuby.instance

#Make the vector an R variable
r.assign('conflictDays',(conflict_days))
#Write the graph
r.png("Conflict_Days_#{event}_diff_users.png",:height=>600,:width=>800)
r.eval_R %{ hist(as.Date(conflictDays, origin="1970-01-01"), breaks="days", main="Histogram of Changeset Conflicts by Day in #{event}", xlab="Day", ylab="Number of Conflicts", freq=TRUE) }
r.eval_R %{ dev.off() }

#Write the conflicts out to json for save keeping
File.open("#{event}_conflict_nodes_diff_users.json",'w') do |f|
  f.write(conflict_nodes.to_json)
end