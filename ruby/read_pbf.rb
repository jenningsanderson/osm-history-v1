'''
PBF Parser from: https://github.com/planas/pbf_parser
'''

require 'pbf_parser'
require 'mongo'

def connect_to_mongo
	client = Mongo::MongoClient.new
	db = client['example-db'] 
	coll = db['example-collection']
	10.times { |i| coll.insert({ :count => i+1 }) }
	puts "There are #{coll.count} total documents. Here they are:"
	coll.find.each { |doc| puts doc.inspect }
end

connect_to_mongo


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
