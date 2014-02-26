'''
PBF Parser from: https://github.com/planas/pbf_parser

//These two are for MongoDB:
gem install mongo
gem install bson_ext

//These two are for parsing PBF:
brew install protobuf-c
gem install pbf_parser
'''

class OSMGeoJSONMongo
	require 'mongo'
	require 'pbf_parser'

	attr_reader :parser
	
	def initialize(db='example-db', collection='example')
		begin
			client = Mongo::MongoClient.new
			db = client[db]
			@coll = db[collection]
		rescue
			puts "Oops, unable to connect to client -- is it running?"
		end
	end

	def Parser(file)
		@parser = PbfParser.new(file)
	end
	
	def addPoint(node)
		this_node = {}
		this_node[:id] = node[:id]
		this_node[:geometry]={:type=>'Point', :coordinates=>[node[:lat], node[:lon]]}
		this_node[:type]="Feature"
		this_node[:properties]=node
		
		return @coll.insert(this_node)
	end

	'''
	I am a bit concerned about this function, it will have to look
	up every referenced node and get the coordinates for it, if we
	want to be able to see it spatially...but for the time being

	... Unless we do this: http://docs.mongodb.org/manual/tutorial/model-referenced-one-to-many-relationships-between-documents/
	'''
	def addLine(way, geo=false)
		this_line = {}
		if way[:refs][0] == way[:refs][-1]
			#Not a foolproof test -- but not enough data to tell...
			this_line[:geometry]={:type=>"Polygon",:coordinates=>[]}
		else
			this_line[:geometry]={:type=>"LineString",:coordinates=>[]}
		end
		this_line[:type]="Feature"
		this_line[:properties]=way

		#TODO: If geo, it will have to loop through the refs and access
		# the lat/lon for each node... yikes!
		return @coll.insert(this_line)
	end

	'''
	This function has all of the same concerns... it will be computationally
	expensive to reference all of the other geometries -- can we use pointers 
	to parts of other documents?
	YES: http://docs.mongodb.org/manual/tutorial/model-referenced-one-to-many-relationships-between-documents/
	'''
	def addRelation(relation, geo=false)
		this_relation = {}
		this_relation[:id]=relation[:id]
		this_relation[:geometry]={:type=>"GeometryCollection",:geometries=>[]}
		this_relation[:type]="Feature"
		this_relation[:properties]=relation
		#TODO: If geo, it will have to loop through the refs and access
		# the lat/lon for each node... yikes
		return @coll.insert(this_relation)
	end
end


def parse_test(conn)
	w_count=0
	while conn.parser.next
		# unless conn.parser.nodes.empty?
		# 	conn.parser.nodes.each do |node|
		# 		conn.addPoint(node)
		# 	end
		# end
		unless conn.parser.ways.empty?
			w_count+= 1
			conn.addLine(conn.parser.ways[0])
		end
		#unless parser.relations.empty?
		#	r_count+= parser.relations.size
		#end
	end
end

if __FILE__==$0
	conn = OSMGeoJSONMongo.new() #Defaults
	parser = conn.Parser("/Users/jenningsanderson/Downloads/denver-boulder.osm.pbf")

	#conn.addPoint(parser.nodes.first())
	#conn.addLine(parser.ways.first())
	parse_test(conn)
end
