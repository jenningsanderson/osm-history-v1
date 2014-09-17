require 'rsruby'
require 'epic-geo' #Custom gem for epic

require_relative '../osm_history_analysis'

#Variables:
event  = 'haiti'
coll   = 'nodes'
host   = 'localhost'
port   = 27017
limit  = 300
export_dir = "../../graph_exports"


####################################################
############   Implicit Runtime    #################
####################################################

osm_driver = OSMHistoryAnalysis.new
collection = osm_driver.connect_to_mongo(db=event,coll=coll, host=host, port=port)

versions = []

results = collection.find(
  {'date' => 
    {'$gt'=>osm_driver.times[event.to_sym][:event],
     '$lt'=>osm_driver.times[event.to_sym][:dw_end]
    }
  },
  {:limit=>limit, :fields=>['properties.version']}
)

count = results.count()
puts "Found #{count} nodes matching query"

results.each_with_index do |node, index|
	versions << node['properties']['version']
	if (index%50000).zero?
		puts "Reached #{index.to_f/count*100}%"
	end
end


##### Export it to R
r = RSRuby.instance

#Cast it to an r variable
r.assign('vers',versions)

r.png("#{export_dir}/node_versions_#{event}.png",:height=>600,:width=>800)
r.eval_R %{ hist(vers, main="Histogram of node versions", xlab="Version", ylab="Count", breaks=100) }
#r.eval_R "axis.Date(1, as.Date(dates, origin=\"1960-10-01\"), format='%m/%d/%Y')"
r.eval_R %{ dev.off() }

