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

	attr_reader :parser, :missing_nodes, :n_count, :w_count, :r_count, :file

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
		@file = file
		@parser = PbfParser.new(file)
	end

	def reset_parser
		@parser = PbfParser.new(@file)
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

	def file_stats
		test_parser = PbfParser.new(@file)
		@n_count = 0
		@w_count = 0
		@r_count = 0
		while test_parser.next
			unless test_parser.nodes.empty?
				@n_count+= test_parser.nodes.size
			end
			unless test_parser.ways.empty?
				@w_count+= test_parser.ways.size
			end
			unless test_parser.relations.empty?
				@r_count+= test_parser.relations.size
			end
		end
		puts "Nodes: #{@n_count}, Ways: #{@w_count}, Relations: #{@r_count}"
	end

	def read_pbf_to_mongo
		#First do nodes
		index = 0
		while @parser.next
			unless @parser.nodes.nil?
				@parser.nodes.each do |node|
					addPoint(node)
					index += 1
					if index%10000==0
						puts "Processed #{index} of #{@n_count} nodes"
					end
				end
			end
		end

		#Ensure the index so that it goes a little faster...
		puts "Adding Index to the id field"
		@nodes.ensure_index(:id => 1)

		puts "Resetting the Parser"
		reset_parser #Reset the parser because 'seek' does not work

		puts "Importing Ways"
		index = 0
		while @parser.next
			unless @parser.ways.nil?
				@parser.ways.each do |way|
					addLine(way, geo_capture=true)
					index += 1
					if index%1000==0
						puts "Processed #{index} of #{@w_count} ways"
					end
				end
			end
		end
		puts "Missing node count: #{missing_nodes}"
	end
end #class


if __FILE__==$0
	conn = OSMGeoJSONMongo.new() #Defaults
	file = ARGV[0]
	parser = conn.Parser(file)

	conn.read_pbf_to_mongo
end
