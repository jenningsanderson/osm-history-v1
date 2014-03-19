'''
PBF Parser from: https://github.com/planas/pbf_parser

//These two are for MongoDB:
gem install mongo
gem install bson_ext

//These two are for parsing PBF:
brew install protobuf-c
gem install pbf_parser

//General Info:
With the size of this data, it should be more efficient to store everything
together so we get a better idea and embed the references in each way, relation
... We could potentially end up with an issue with duplicates if we try to update
an area, but we could filter based on unique changesets -- as well as rely on
official history files and simply drop the table whenever.
'''

require 'pp'

class OSMGeoJSONMongo

	''' Is there something amuck with the timestamp?'''
	require 'mongo'
	require 'pbf_parser'

	attr_reader :parser, :missing_nodes

	def initialize(database='osmtestdb') #This would be a particular area that we import.
		begin
			client = Mongo::MongoClient.new
			@db = client[database]

			#Collections
			@nodes = @db['nodes']
			@ways  = @db['ways']
			@rels  = @db['relations']
			puts "Successfully connected to #{database}"
		rescue
			puts "Oops, unable to connect to client -- is it running?"
		end
		@missing_nodes=0
	end

	def Parser(file)
		@parser = PbfParser.new(file)
	end

	def addPoint(node)
		this_node = {}
		this_node[:id] = node[:id]
		this_node[:geometry]={:type=>'Point', :coordinates=>[node[:lon],node[:lat]]} #Critical to swap these
		this_node[:type]="Feature"
		this_node[:properties]=node
		return @nodes.insert(this_node)
	end

	def addLine(way, geo_capture=false)
		this_line = {}
		if way[:refs][0] == way[:refs][-1]
			#Not a foolproof test -- but not enough data to tell...
			this_line[:geometry]={:type=>"Polygon",:coordinates=>[]}
		else
			this_line[:geometry]={:type=>"LineString",:coordinates=>[]}
		end
		this_line[:type]="Feature"
		this_line[:properties]=way

		if geo_capture
			way[:refs].each do |node_id|
				geo = @nodes.find({"id"=>node_id},
					:fields=>{"_id"=>1,"geometry.coordinates"=>1}).first
				unless geo.nil?
					this_line[:geometry][:coordinates] << geo["geometry"]["coordinates"]
				else
					@missing_nodes +=1
				end
			end
		end
		return @ways.insert(this_line)
	end

	def addRelation(relation, geo=false)
		this_relation = {}
		this_relation[:id]=relation[:id]
		this_relation[:geometry]={:type=>"GeometryCollection",:geometries=>[]}
		this_relation[:type]="Feature"
		this_relation[:properties]=relation
		#TODO: If geo, it will have to loop through the refs and access
		# the lat/lon for each node... yikes

		# -- But that is really only important if we NEED the geo-spatial refs

		return @rels.insert(this_relation)
	end
end


def read_pbf_to_mongo(conn)
	while conn.parser.next
		unless conn.parser.nodes.empty?
			conn.parser.nodes.each do |node|
				conn.addPoint(node)
			end
		end
		unless conn.parser.ways.empty?
			conn.parser.ways.each do |way|
				conn.addLine(way, geo_capture=true)
			end
		end
		#unless parser.relations.empty?
		#	r_count+= parser.relations.size
		#end
	end
	puts "Missing node count: #{conn.missing_nodes}"
end


if __FILE__==$0
	conn = OSMGeoJSONMongo.new() #Defaults
	file = ARGV[0]
	parser = conn.Parser(file)

	#conn.addPoint(parser.nodes.first())
	#conn.addLine(parser.ways.first())
	read_pbf_to_mongo(conn)
end
