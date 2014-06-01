#Require system stuff
require 'json'
require 'mongo'

#Require custom classes
require 'epic-geo'
require_relative 'osm_history_analysis'

#Define bounding boxes and then find nodes within that box.  Export to GeoJSON
class VisualizeChangesetsByUser

	#Define the bounding boxes we'll use
	@@port_au_prince = [[[-72.3497538756,18.5401432083],[-72.3497538756,18.5545791745],[-72.3321783064,18.5545791745],[-72.3321783064,18.5401432083],[-72.3497538756,18.5401432083]]],
	@@port_au_prince_hot_spot = [[[-72.3239832114,18.579134142],[-72.3239832114,18.605817724],[-72.2910010336,18.605817724],[-72.2910010336,18.579134142],[-72.3239832114,18.579134142]]]
	@@port_au_prince_big = [[[-72.3504190634,18.5208741622],[-72.3504190634,18.5996334086],[-72.2494589804,18.5996334086],[-72.2494589804,18.5208741622],[-72.3504190634,18.5208741622]]]
	
	@@tacloban = [[[124.9984297355,11.2408310012],[124.9984297355,11.2529731375],[125.0123575004,11.2529731375],[125.0123575004,11.2408310012],[124.9984297355,11.2408310012]]]
	@@tacloban_big = [[[124.9801477989,11.2284559632],[124.9801477989,11.2540671851],[125.010555056,11.2540671851],[125.010555056,11.2284559632],[124.9801477989,11.2284559632]]]
	@@tacloban_bigger = [[[124.9959406456,11.1999155283],[124.9959406456,11.2394188144],[125.0314977439,11.2394188144],[125.0314977439,11.1999155283],[124.9959406456,11.1999155283]]]

	def initialize
		@osm_data = OSMHistoryAnalysis.new
	end

	#Hit the nodes collection with the specific query parameters
	def hit_mongo_nodes(dataset = 'haiti', limit = 100, bbox = nil )
		this_bbox = instance_eval("@@#{bbox}")
		coll = @osm_data.connect_to_mongo(dataset=dataset, coll='nodes')
		coll.find(
				selector = {'geometry' => {'$geoWithin' =>
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
							'geometry' => {'$geoIntersects' =>
												{'$geometry'=>{'type'=>'Polygon',
															   'coordinates'=> this_bbox}}},
							'created_at'=> {"$gt" => @osm_data.times[dataset.to_sym][:event], "$lt"=> @osm_data.times[dataset.to_sym][:one_week_after]}
						    },
				opts = {:limit=>limit})
	end
end


'''Actual runtime here'''
if $0 == __FILE__
	puts "Running geojson visualization export"

	getter = VisualizeChangesetsByUser.new

	bbox='tacloban_bigger'
	dataset='philippines'

	node_res = getter.hit_mongo_nodes(dataset=dataset,limit=100, bbox=bbox)
	changeset_res = getter.hit_mongo_changesets(dataset=dataset,limit=nil,bbox=bbox)


	changeset_outfile = GeoJSONWriter.new("geojson_exports/#{bbox}_1week_changesets")
	changeset_outfile.write_header

	puts changeset_res.count
	changeset_res.each do |changeset|
		changeset_outfile.write_feature changeset['geometry'], {:user=>changeset['user'],:created_at=>changeset['created_at'].strftime("%Y-%m-%d %H:%M:%S")}
	end

	changeset_outfile.write_footer


	# outfile = GeoJSONWriter.new("geojson_exports/#{bbox}_1week_lim100.geojson")
	# outfile.write_header


	# res.each do |node|
	#  	outfile.write_feature(node['geometry'],node['properties'])
	# end

	# outfile.write_footer
end


