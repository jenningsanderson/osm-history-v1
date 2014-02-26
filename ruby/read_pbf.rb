'''
PBF Parser from: https://github.com/planas/pbf_parser

//These two are for MongoDB:
gem install mongo
gem install bson_ext

//These two are for parsing PBF:
brew install protobuf-c
gem install pbf_parser
'''

require 'pbf_parser'

class OSMGeoJSONMongo
	require 'mongo'
	def initialize(db='example-db', collection='example-collection')
		begin
			client = Mongo::MongoClient.new
			db = client[db]
			@coll = db[collection]
		rescue
			puts "Oops, unable to connect to client -- is it running?"
		end
	end
	
	def addPoint()

	end

	def addLine()

	end

	def addPolygon()

	end
end



this_connection = OSMGeoJSONMongo.new() #Defaults


def parse_test
	parser = PbfParser.new("/Users/jenningsanderson/Downloads/nepal.osm.pbf")

	n_count = 0
	w_count = 0
	r_count = 0

	while parser.next
		unless parser.nodes.empty?
			n_count+= parser.nodes.size
		end
		unless parser.ways.empty?
			w_count+= parser.ways.size
		end
		unless parser.relations.empty?
			r_count+= parser.relations.size
		end
	end
	puts "Nodes: #{n_count}, Ways: #{w_count}, Rels: #{r_count}"
end

'''
TODO: Intelligently convert nodes to points, ways to lines, and relations
to polygons

Create these fields and then push the file to MongoDB.  From there we 
can make spatial queries
'''

'''
Connect to MongoDB
'''
