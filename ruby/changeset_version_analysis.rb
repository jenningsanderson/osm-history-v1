require 'mongo'
require 'rsruby'
require 'optparse'
require 'ostruct'
require 'rgeo'
require 'rgeo/geo_json'
require 'csv'
require 'epic-geo' #Custom gem for epic

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

#Connect to Mongo --> Choose your db here
CONN = Mongo::MongoClient.new('epic-analytics.cs.colorado.edu', 27018)
DB = CONN[event]
COLL = DB['nodes']

versions = []

results = COLL.find({'date' => {'$gt'=>TIMES[event.to_sym][:start],'$lt'=>TIMES[event.to_sym][:end]}},
					{:limit=>nil, :fields=>['properties.version']})
count = results.count()
puts "Found #{count} nodes matching query"

results.each_with_index do |node, index|
	versions << node['properties']['version']
	if (index%50000).zero?
		puts "Reached #{index.to_f/count*100}%"
	end
end

r = RSRuby.instance

#Cast it to an r variable
r.assign('vers',versions)

r.png("node_versions_#{event}.png",:height=>600,:width=>800)
r.eval_R %{ hist(vers), main="Histogram of node versions", xlab="Version", ylab="Count", breaks=100) }
r.eval_R %{ dev.off() }

