require 'pbf_parser'

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
