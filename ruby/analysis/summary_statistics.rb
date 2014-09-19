#
# Simple summarative statistics (easier than writing mapreduce functions)
#

require_relative '../osm_history_analysis'

if __FILE__ == $0

	osm_driver = OSMHistoryAnalysis.new(:local)

	haiti = osm_driver.connect_to_mongo(db='haiti')
	phil  = osm_driver.connect_to_mongo(db='phil')



	puts "\nHaiti Summary Statistics:"
	puts "========================="

	########################## NODES IN DISASTER WINDOW #####################
	# h_nodes = haiti['nodes'].find(
	# 	{
	# 		:date => {'$gt' => osm_driver.dates[:haiti][:event],
	# 				  '$lt' => osm_driver.dates[:haiti][:dw_end]
	# 					   }
	# 		#:"properties.version" => 1
	# 	})
	# puts "Nodes edited in Disaster window: #{h_nodes.count}"

	########################## DISTINCT CHANGESETS ##########################
	# print "Calculating Distinct Changesets: "
	# node_changes = haiti['nodes'].distinct("properties.changeset")
	# way_changes  = haiti['ways'].distinct("properties.changeset")
	# rel_changes  = haiti['relations'].distinct("properties.changeset")
	# puts (node_changes + way_changes+rel_changes).uniq.length




	puts "-------------------------"



	puts "\nPhil Summary Statistics:"
	puts "========================="

	######################### NODES IN DISASTER WINDOW #####################
	p_nodes = phil['nodes'].find(
		{
			:date => {'$gt' => osm_driver.dates[:philippines][:event],
					  '$lt' => osm_driver.dates[:philippines][:dw_end]
						   }
			#:"properties.version" => 1
		})
	puts "Nodes edited in Disaster window: #{p_nodes.count}"


	########################## DISTINCT CHANGESETS ##########################
	print "Calculating Distinct Changesets: "
	node_changes = phil['nodes'].distinct("properties.changeset")
	way_changes  = phil['ways'].distinct("properties.changeset")
	rel_changes  = phil['relations'].distinct("properties.changeset")
	puts (node_changes + way_changes+rel_changes).uniq.length




	puts "-------------------------"

end