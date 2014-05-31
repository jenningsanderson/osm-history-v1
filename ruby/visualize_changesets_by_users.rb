require 'json'
require 'epic-geo'
require 'mongo'

#As usual, define the query time limits per dataset
QUERY_TIME = {    :haiti=>{
					:event=>Time.new(2010,1,12),
                    :start=>Time.new(2010,01,12),
                    :end  =>Time.new(2010,01,19)},

                  :philippines=>{ 
                  	:event=>Time.new(2013,11,8),
                    :start=>Time.new(2013,11,8),
                    :end  =>Time.new(2013,11,15)}
               }

'''Hit the Mongo Nodes collection per dataset, with the custom defined bounding boxes'''
def hit_mongo( dataset = 'haiti',
			   limit = 100,
			   bbox = 'port_au_prince' )
	
	port_au_prince = [[[-72.3497538756,18.5401432083],[-72.3497538756,18.5545791745],[-72.3321783064,18.5545791745],[-72.3321783064,18.5401432083],[-72.3497538756,18.5401432083]]],
	port_au_prince_hot_spot = [[[-72.3239832114,18.579134142],[-72.3239832114,18.605817724],[-72.2910010336,18.605817724],[-72.2910010336,18.579134142],[-72.3239832114,18.579134142]]]
	tacloban = [[[124.9984297355,11.2408310012],[124.9984297355,11.2529731375],[125.0123575004,11.2529731375],[125.0123575004,11.2408310012],[124.9984297355,11.2408310012]]]
	
	#CONN = Mongo::MongoClient.new #Defaults to localhost
	conn = Mongo::MongoClient.new('epic-analytics.cs.colorado.edu',27018)
	db = conn[dataset]
	coll = db['nodes']

	puts "Connected to Mongo"

	coll.find(
			selector = {'geometry' => {'$geoWithin' =>
											{'$geometry'=>{'type'=>'Polygon',
														   'coordinates'=>instance_eval(bbox)}}},
						'date'=> {"$gt" => QUERY_TIME[dataset.to_sym][:start], "$lt"=> QUERY_TIME[dataset.to_sym][:end]}
					    },
			opts = {:limit=>limit})
end


if $0 == __FILE__
	puts "Running geojson visualization export"

	bbox='tacloban'
	dataset = 'philippines'

	res = hit_mongo(dataset=dataset,limit=nil, bbox=bbox)

	#These are the first 100 nodes from port-au-prince, lets write them to geojson
	
	outfile = GeoJSONWriter.new("geojson_exports/#{bbox}_1week.geojson")
	outfile.write_header


	res.each do |node|
		outfile.write_feature(node['geometry'],node['properties'])
	end

	outfile.write_footer
end


