'''
PBF Parser from: https://github.com/planas/pbf_parser

//These two are for MongoDB:
gem install mongo
gem install bson_ext

//These two are for parsing PBF:
brew install protobuf-c (Mac)
gem install pbf_parser
'''

require './OSMGeoJSONMongo.rb'


if __FILE__==$0
	if ARGV[0].nil?
		puts "Call this in the following manner: "
		puts "\truby read_pbf.rb [database name] [pbf file]"
	else
		db 		= ARGV[0]
		file 	= ARGV[1]
		unless ARGV[2].nil?
			limit  = ARGV[2].to_i
		end

		limit ||= nil

		if file=="kath"
			file = '/Users/jenningsanderson/Documents/OSM/Extracts/kathmandu.osm.pbf'
		end

		puts "Calling import with limit: #{limit}"

		#Create connection
		conn = OSMGeoJSONMongo.new(db) #Defaults
		parser = conn.Parser(file)

		puts "Information about your file"
		conn.file_stats

		puts "Beginning Mongo Import"
		conn.read_pbf_to_mongo(lim=limit)
	end
end
