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
		parser = conn.Parser(file)

		puts "Information about your file"
		conn.file_stats

		puts "Beginning Mongo Import"
		conn.read_pbf_to_mongo
		puts "Missing node count: #{conn.missing_nodes}"
	end
end
