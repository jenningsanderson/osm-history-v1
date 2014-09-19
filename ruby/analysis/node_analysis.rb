#
# Basic Node Analysis
#

require_relative '../osm_history_analysis'



country = "phil"




if __FILE__ == $0

	osm_driver = OSMHistoryAnalysis.new(:local)

	nodes = osm_driver.connect_to_mongo(db=country, coll="nodes")
	users = osm_driver.connect_to_mongo(db=country, coll="users")
	changesets = osm_driver.connect_to_mongo(db=country, coll="changesets")

	puts "Node Summary for #{country}"
	puts "==========================="

	print "Nodes added during DW: "
	puts nodes.find({:date => {
							'$gt' => osm_driver.dates[country.to_sym][:event],
							'$lt' => osm_driver.dates[country.to_sym][:dw_end]
							},
					 :"properties.version"=>1
				 				}).count

	#############################   WHO EDITED THE NODES?   ####################################
	print "Nodes edited by Existing Users: "
	older_user_sum = 0

	#User edited during disaster window and is an existing user
	users.distinct("uid",{:dw=>true, :"account_created" => {'$lt' => osm_driver.dates[country.to_sym][:event]}}).each do |uid|
		sum = changesets.find({"uid"=>uid.to_s, :nodes => true,
										:created_at => {
											'$gt' => osm_driver.dates[country.to_sym][:event],
											'$lt' => osm_driver.dates[country.to_sym][:dw_end]}
										})
		unless sum.count.zero?
			older_user_sum += sum.collect{|changeset| changeset["node_count"]}.inject(:+)
		end
	end
	puts older_user_sum




	print "Nodes edited by New Users: "
	new_user_sum = 0
	users.distinct("uid",{:dw=>true, :"account_created" => {'$gt' => osm_driver.dates[country.to_sym][:event]}}).each do |uid|
		sum = changesets.find({"uid"=>uid.to_s, :nodes=> true,
										:created_at => {
											'$gt' => osm_driver.dates[country.to_sym][:event],
											'$lt' => osm_driver.dates[country.to_sym][:dw_end]}
										})
		unless sum.count.zero?
			new_user_sum += sum.collect{|changeset| changeset["node_count"]}.inject(:+)
		end
	end
	puts new_user_sum





end