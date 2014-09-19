#
# Basic User Analysis Queries
#
# Calculate s
#

require_relative '../osm_history_analysis'



country = "phil"



if __FILE__ == $0

	unless ARGV.empty?
		country = ARGV[0]
	end

	osm_driver = OSMHistoryAnalysis.new(:local)

	users = osm_driver.connect_to_mongo(db=country, coll="users")
	changesets = osm_driver.connect_to_mongo(db=country, coll="changesets")

	puts "User Summary for #{country}"
	puts "==========================="

	puts "Users that edited during the DW and joined before it started (Experienced Users)"
	
	exp_users = users.find({"dw" => true,
				 	  "account_created" => {'$lt' => osm_driver.dates[country.to_sym][:event]}
				 	})

	puts "Number of experienced users: #{exp_users.count}"
	print "Number of changesets by experienced users: "
	sum = 0
	exp_users.each do |user|
		sum += changesets.find({:uid => user["id"], 
								:created_at => {
									'$gt' => osm_driver.dates[country.to_sym][:event],
									'$lt' => osm_driver.dates[country.to_sym][:dw_end]}
				 				}).count
	end

	puts sum

	puts "Users that edited during the DW and joined after it started (New users)"
	
	new_users = users.find({"dw" => true,
				 	  "account_created" => {'$gt' => osm_driver.dates[country.to_sym][:event]}
				 	})
	puts "Number of New Users: #{new_users.count}"
	print "Number of changesets by new users: "
	sum = 0
	new_users.each do |user|
		sum += changesets.find({:uid => user["id"], 
								:created_at => {
									'$gt' => osm_driver.dates[country.to_sym][:event],
									'$lt' => osm_driver.dates[country.to_sym][:dw_end]}
				 				}).count
	end

	puts sum

	print "Total Users who edited during the event: "
	puts users.find({"dw"=> true}).count


	# puts "===================================================="
	# changesets_per_mapper = []
	# puts "Changesets Per Mapper Statistics:"
	# users.find({"dw"=>true}).each do |user|
	# 	changesets_per_mapper << changesets.find(
	# 					{:uid => user["id"], :created_at => {
	# 						'$gt' => osm_driver.dates[country.to_sym][:event],
	# 						'$lt' => osm_driver.dates[country.to_sym][:dw_end]}
	# 			 				}).count
	# end

	# stats = DescriptiveStatistics::Stats.new(changesets_per_mapper)
	# puts "Mean Changesets per Mapper: #{stats.mean}"
	# puts "Median Changesets per Mapper: #{stats.median}"
	# puts "Mode Changesets per Mapper: #{stats.mode}"



	puts "===================================================="
	nodes_per_mapper = []
	puts "Nodes per user statistics: "
	
	users.find({"dw"=>true}).each do |user|
		nodes_per_mapper << changesets.find(
						{:uid => user["id"], :node_count =>{'$lt' => 10000}, :created_at => {
							'$gt' => osm_driver.dates[country.to_sym][:event],
							'$lt' => osm_driver.dates[country.to_sym][:dw_end]}
				 				}).collect{|x| x["node_count"]}.inject(:+)
	end

	stats = DescriptiveStatistics::Stats.new(nodes_per_mapper.compact) #Compact to remove nil values
	puts "Mean Nodes edited per Mapper: #{stats.mean}"
	puts "Median Nodes edited per Mapper: #{stats.median}"
	puts "Mode Nodes edited per Mapper: #{stats.mode}"


end
