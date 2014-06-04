#Require system stuff
require 'json'
require 'mongo'
require 'time'

#Require custom classes
require 'epic-geo'
require_relative 'osm_history_analysis'

#Define bounding boxes and then find nodes within that box.  Export to GeoJSON
class VisualizeChangesetsByUser

	#Define the bounding boxes we'll use
	@@port_au_prince = [[[-72.3497538756,18.5401432083],[-72.3497538756,18.5545791745],[-72.3321783064,18.5545791745],[-72.3321783064,18.5401432083],[-72.3497538756,18.5401432083]]],
	@@port_au_prince_hot_spot = [[[-72.3239832114,18.579134142],[-72.3239832114,18.605817724],[-72.2910010336,18.605817724],[-72.2910010336,18.579134142],[-72.3239832114,18.579134142]]]
	@@port_au_prince_big = [[[-72.3504190634,18.5208741622],[-72.3504190634,18.5996334086],[-72.2494589804,18.5996334086],[-72.2494589804,18.5208741622],[-72.3504190634,18.5208741622]]]
	@@port_au_prince_sw = [[[-72.4995928,18.4505195698],[-72.4995928,18.560279789],[-72.3018157004,18.560279789],[-72.3018157004,18.4505195698],[-72.4995928,18.4505195698]]]
	@@port_au_prince_focus = [[[-72.3330812644,18.5398818461],[-72.3330812644,18.5449130477],[-72.3275649069,18.5449130477],[-72.3275649069,18.5398818461],[-72.3330812644,18.5398818461]]]
	@@port_au_prince_focus_2 = [[[-72.3384885977,18.57543906],[-72.3384885977,18.5804702616],[-72.3329722403,18.5804702616],[-72.3329722403,18.57543906],[-72.3384885977,18.57543906]]]

	@@pap_big_big = [[[-72.3584013175,18.5293834573],[-72.3584013175,18.5804702616],[-72.2957217215,18.5804702616],[-72.2957217215,18.5293834573],[-72.3584013175,18.5293834573]]]
	@@pap_big_bigger = [[[-72.4322157095,18.4929207516],[-72.4322157095,18.5858397352],[-72.2806155203,18.5858397352],[-72.2806155203,18.4929207516],[-72.4322157095,18.4929207516]]]

	@@tacloban = [[[124.9984297355,11.2408310012],[124.9984297355,11.2529731375],[125.0123575004,11.2529731375],[125.0123575004,11.2408310012],[124.9984297355,11.2408310012]]]
	@@tacloban_big = [[[124.9801477989,11.2284559632],[124.9801477989,11.2540671851],[125.010555056,11.2540671851],[125.010555056,11.2284559632],[124.9801477989,11.2284559632]]]
	@@tacloban_bigger = [[[124.9959406456,11.1999155283],[124.9959406456,11.2394188144],[125.0314977439,11.2394188144],[125.0314977439,11.1999155283],[124.9959406456,11.1999155283]]]
	@@tacloban_huge = [[[124.9684748252,11.2170062565],[124.9684748252,11.2628217452],[125.0393941673,11.2628217452],[125.0393941673,11.2170062565],[124.9684748252,11.2170062565]]]
	@@tacloban_focus = [[[124.9971422752,11.2401579984],[124.9971422752,11.2530568466],[125.0110700401,11.2530568466],[125.0110700401,11.2401579984],[124.9971422752,11.2401579984]]]

	@@tacloban_again = [[[124.9737963279,11.1941948334],[124.9737963279,11.2549036399],[125.034244326,11.2549036399],[125.034244326,11.1941948334],[124.9737963279,11.1941948334]]]
	@@tacloban_south = [[[124.9902758201,11.1896423442],[124.9902758201,11.2178678414],[125.0289228233,11.2178678414],[125.0289228233,11.1896423442],[124.9902758201,11.1896423442]]]

	def initialize
		@osm_data = OSMHistoryAnalysis.new
	end

	#Hit the nodes collection with the specific query parameters
	def hit_mongo_nodes(dataset = 'haiti', limit = 100, bbox = nil )
		this_bbox = instance_eval("@@#{bbox}")
		coll = @osm_data.connect_to_mongo(dataset=dataset, coll='nodes')
		coll.find(
				selector = {'properties.version'=>1,
							'geometry' => {'$geoWithin' =>
												{'$geometry'=>{'type'=>'Polygon',
															   'coordinates'=> this_bbox}}},
							'date'=> {"$gt" => @osm_data.times[dataset.to_sym][:event], "$lt"=> @osm_data.times[dataset.to_sym][:one_week_after]}
						    },
				opts = {:limit=>limit})
	end

	def hit_mongo_ways(dataset = 'haiti', limit = 100, bbox = nil )
		this_bbox = instance_eval("@@#{bbox}")
		coll = @osm_data.connect_to_mongo(dataset=dataset, coll='ways')
		coll.find(
				selector = {'properties.version'=>1,
							'geometry' => {'$geoWithin' =>
												{'$geometry'=>{'type'=>'Polygon',
															   'coordinates'=> this_bbox}}},
							'date'=> {"$gt" => @osm_data.times[dataset.to_sym][:event], "$lt"=> @osm_data.times[dataset.to_sym][:one_week_after]}
						    },
				opts = {:limit=>limit})
	end

	#Hit the changeset collections with the specific query parameters
	def hit_mongo_changesets(dataset='haiti',limit=100,bbox=nil)
		this_bbox = instance_eval("@@#{bbox}")
		coll = @osm_data.connect_to_mongo(dataset=dataset, coll='changesets')
		coll.find(
				selector = {'area' => {'$lt'=>100000},
							'geometry' => {'$geoWithin' =>
												{'$geometry'=>{'type'=>'Polygon',
															   'coordinates'=> this_bbox}}},
							'created_at'=> {"$gt" => @osm_data.times[dataset.to_sym][:event], "$lt"=> @osm_data.times[dataset.to_sym][:dw_end]}
						    },
				opts = {:limit=>limit})
	end
end


'''Actual runtime here'''
if $0 == __FILE__
	puts "Running geojson visualization export"

	getter = VisualizeChangesetsByUser.new

	bbox='tacloban_again'
	dataset='philippines'

	#Nodes
	# node_res = getter.hit_mongo_nodes(dataset=dataset,limit=nil, bbox=bbox)

	# puts node_res.count()

	# outfile = GeoJSONWriter.new("geojson_exports/#{bbox}_62k_nodes_v1_first_week")
	# outfile.write_header
	# node_res.each do |node|
	#   	outfile.write_feature(node['geometry'],
	#   		{:id=>node['properties']['id'],
	#   		 :tags=>node['properties']['tags'],
	#   		 :user=>node['properties']['user'],
	#   		 :version=>node['properties']['version'],
	#   		 :time=>node['date'].strftime("%Y-%m-%d %H:%M:%S"),
	#   		 :set=>node['properties']['changeset']})
	# end
	# outfile.write_footer

	# Ways
	way_res = getter.hit_mongo_ways(dataset=dataset, limit=nil, bbox=bbox)
	outfile = GeoJSONWriter.new("geojson_exports/#{bbox}_1week_ways_v1")
	outfile.write_header
	way_res.each do |way|
	  	outfile.write_feature(way['geometry'],
	  		{:id=>way['properties']['id'],
	  		 :tags=>way['properties']['tags'],
	  		 :user=>way['properties']['user'],
	  		 :version=>way['properties']['version'],
	  		 :time=>way['date'].strftime("%Y-%m-%d %H:%M:%S"),
	  		 :end => "2010-02-12 00:00:00",
	  		 :set=>way['properties']['changeset']})
	end
	outfile.write_footer


	#Changesets
	changeset_res = getter.hit_mongo_changesets(dataset=dataset,limit=nil,bbox=bbox)
	changeset_outfile = GeoJSONWriter.new("geojson_exports/#{bbox}_dw_changesets")
	changeset_outfile.write_header
	puts changeset_res.count
	changeset_res.each do |changeset|
		changeset_outfile.write_feature changeset['geometry'], {:id=>changeset['id'],:user=>changeset['user'],:created_at=>changeset['created_at'].strftime("%Y-%m-%d %H:%M:%S"), :nodes=>changeset['node_count'].to_i}
	end

	changeset_outfile.write_footer

	
end


