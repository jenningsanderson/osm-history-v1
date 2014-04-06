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
require 'time'

class OSMGeoJSONMongo
	''' Is there something amuck with the timestamp?'''

	require 'mongo'
	require 'pbf_parser'
	require 'date'

	attr_reader :parser, :missing_nodes, :n_count, :w_count, :r_count, :file

	def initialize(database) #This would be a particular area that we import. (eg. Nepal)
		begin
			client = Mongo::MongoClient.new
			@db = client[database]

			#Collections
			@nodes = @db['nodes']
			@ways  = @db['ways']
			@relations  = @db['relations']
			puts "Successfully connected to #{database}"
		rescue
			puts "Oops, unable to connect to client -- is it running?"
			exit
		end

		@missing_nodes=0
		@empty_lines = 0
		@empty_geometries = 0

		@n_count = 0
		@w_count = 0
		@r_count = 0
	end

	#Initialize the pbf parser from the file
	def Parser(file)
		@file = file
		@parser = PbfParser.new(file)
	end

	#If the function @parser.seek(0) worked, it would be better...
	def reset_parser
		@parser = nil
		@parser = PbfParser.new(@file)
	end

	def get_geometry(coll, id)
		geo = coll.find({"id"=>id},
		opts = {
			:sort  =>["properties.version", Mongo::DESCENDING],
			:fields=>{"_id"=>0,"geometry"=>1}}).first

		unless geo.nil?
			return geo["geometry"]
		else
			@missing_nodes +=1
			return nil
		end
	end

	def add_node(node)
		this_node = {}
		this_node[:date] = Time.at(node[:timestamp]/1000).utc
		this_node[:id] = node[:id]
		this_node[:geometry]={:type=>'Point', :coordinates=>[node[:lon],node[:lat]]} #Critical to swap these
		this_node[:type]="Feature"
		this_node[:properties]=node
		return @nodes.insert(this_node)
	end

	def add_way(way)
		this_line = {}
		this_line[:id] = way[:id]
		this_line[:date] = Time.at(way[:timestamp]/1000).utc

		#Determine the type of geometry based on if it's closed or not.  Could mis-identify, but it's the best we can do.
		this_line[:geometry] = {:coordinates=>[]}
		this_line[:type]="Feature"
		this_line[:properties]=way

		#Query the nodes collection for the coords of each point it references
		way[:refs].each do |node_id|
			coords = get_geometry(@nodes, node_id)
			if coords
				this_line[:geometry][:coordinates] << coords["coordinates"]
			end
		end

		if this_line[:geometry][:coordinates].empty?
			@empty_lines +=1
			this_line.delete(:geometry)
		else
			if (this_line[:geometry][:coordinates].count > 2) & (way[:refs][0] == way[:refs][-1])
				this_line[:geometry][:type] = "Polygon"
			else
				this_line[:geometry][:type] = "LineString"
			end
		end

		return @ways.insert(this_line)
	end

	def add_relation(relation)
		this_relation = {}
		this_relation[:id]=relation[:id]
		this_relation[:geometry]={:type=>"GeometryCollection",:geometries=>[]}
		this_relation[:type]="Feature"
		this_relation[:properties]=relation

		@missing_nodes = 0
		@empty_lines = 0
		@empty_geomtries =0

		relation[:members][:nodes].each do |node_ref|
			geometry = get_geometry(@nodes, node_ref)
			unless geometry.nil?
				this_relation[:geometries] << geometry
			else
				@missing_nodes += 1
			end
		end

		relation[:members][:ways].each do |way_ref|
			geometry = get_geometry(@ways, way_ref)
			unless geometry.nil?
				this_relation[:geometries] << geometry
			else
				@empty_lines += 1
			end
		end

		if this_relation[:geometry][:geometries].empty?
			@empty_geometries +=1
			this_relation.delete(:geometry)
		end

		return @relations.insert(this_relation)
	end

	def file_stats
		test_parser = PbfParser.new(@file)
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

	def parse_to_collection(object_type, lim=nil)
		start_time = Time.now
    puts "Started #{object_type} import at: #{start_time}"
		reset_parser #Reset the parser because 'seek' does not work

		@missing_nodes = 0
		index = 0
		add_func = method("add_#{object_type[0..-2]}")
		count = eval("@#{object_type[0]}_count")

		while @parser.next
			unless @parser.send(object_type).nil?
				if lim
					to_parse = @parser.send(object_type).first(lim)
				else
					to_parse = @parser.send(object_type)
				end
				to_parse.each do |obj|
					begin
						add_func.call(obj)
						index += 1
					rescue => e
						p $!
						#p e.backtrace
						begin
							type["tags"].each do |k,v|
								k.gsub!('.','_')
							end
							add_func.call(obj)
						rescue
							next
						end
					end
					if index%2000==0
						puts "Processed #{index} of #{count} #{object_type}"
						if index%10000==0
        			rate = index/(Time.now() - start_time) #Tweets processed / seconds elapsed
        			mins = (count-index) / rate / 60         #minutes left = tweets left * seconds/tweet / 60
        			hours = mins / 60
        			puts "Status: #{'%.2f' % rate} #{object_type}/Second. #{'%.2f' % mins} minutes left or #{'%.2f' % hours} hours."
						end
					end
				end
			end
		end

		puts "Adding the appropriate indexes"
		begin
			eval %Q{@#{object_type}.ensure_index(:id => 1)}
			eval %Q{@#{object_type}.ensure_index(:geometry =>"2dsphere")}
		rescue
			puts "Error creating index"
			p $!
		end
	end

	def read_pbf_to_mongo(lim=nil)
		puts "\nImporting Nodes"
		parse_to_collection('nodes', lim=lim)

		puts "\nImporting Ways"
		parse_to_collection('ways', lim=lim)
		puts "Missing node count: #{@missing_nodes}"
		puts "Empty way count: #{@empty_lines}"

		puts "\nImporting Relations"
		parse_to_collection('relations', lim=lim)
		puts "Missing node count: #{@missing_nodes}"
		puts "Empty way count: #{@empty_lines}"
		puts "Empty Geometries: #{@empty_geometries}"

	end
end #class


if __FILE__==$0
	conn = OSMGeoJSONMongo.new("osm_test_db") #Defaults
	file = ARGV[0]
	parser = conn.Parser(file)

	conn.read_pbf_to_mongo
end
