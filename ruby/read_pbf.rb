'''
PBF Parser from: https://github.com/planas/pbf_parser

//These two are for MongoDB:
gem install mongo
gem install bson_ext

//These two are for parsing PBF:
brew install protobuf-c
gem install pbf_parser
'''

require './OSMGeoJSONMongo.rb'

def file_stats(file)
	parser = PbfParser.new(file)
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

if __FILE__==$0
	if ARGV[0].nil?
		puts "Call this in the following manner: "
		puts "\truby read_pbf.rb [database name] [pbf file]"
	else
		db = ARGV[0]
		file = ARGV[1]

		if db=="nepal"
			file = '/Users/jenningsanderson/Downloads/nepal.osm.pbf'
		end

		#Create connection
		conn = OSMGeoJSONMongo.new(database=db) #Defaults

		puts "Information about your file: "
		file_stats(file)

		parser = conn.Parser(file)
		read_pbf_to_mongo(conn)
		puts "Missing node count: #{conn.missing_nodes}"
	end
end
