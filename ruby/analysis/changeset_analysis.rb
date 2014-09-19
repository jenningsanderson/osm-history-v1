#
# Basic Changeset Analysis Queries
#

require_relative '../osm_history_analysis'


country = "haiti"


if __FILE__ == $0

	unless ARGV.empty?
		country = ARGV[0]
	end

	osm_driver = OSMHistoryAnalysis.new(:local)

	changesets = osm_driver.connect_to_mongo(db=country, coll="changesets")

	puts "Changeset Summary for #{country}"
	puts "==========================="

	print "Changesets during the DW: "
	puts changesets.find({:created_at => {
							'$gt' => osm_driver.dates[country.to_sym][:event],
							'$lt' => osm_driver.dates[country.to_sym][:dw_end]}
				 				}).count

	print "Distinct users that made these changesets: "
	puts changesets.distinct("uid",{:created_at => {
						'$gt' => osm_driver.dates[country.to_sym][:event],
						'$lt' => osm_driver.dates[country.to_sym][:dw_end]}
			 				}).count



	puts "-----------------------------------------------------------------"
	puts "Calculating Changeset sizes and densities..."
	geo_factory = osm_driver.build_factory

	areas = []

	dw_changesets = changesets.find({:node_count => {'$lt' => 10000, '$gt'=>2}, 
									 :"geometry.type"=>{'$ne'=>"Point"},
									 :created_at => {
							'$gt' => osm_driver.dates[country.to_sym][:event],
							'$lt' => osm_driver.dates[country.to_sym][:dw_end]}
				 				})

	areas = []
	densities = []
	dw_changesets.each do |changeset|
		area = RGeo::GeoJSON.decode(changeset["geometry"], {:geo_factory=>geo_factory, :json_parser=>:json}).area/1000000
		areas << area
		densities << changeset["node_count"] / (area)
	end

	stats = DescriptiveStatistics::Stats.new(areas) #Compact to remove nil values
	puts "Mean Changeset Area: #{stats.mean}"
	puts "Median Changeset Area: #{stats.median}"
	puts "Mode Changeset Area: #{stats.mode}"


	stats = DescriptiveStatistics::Stats.new(densities) #Compact to remove nil values
	puts "Mean Changeset Density: #{stats.mean}"
	puts "Median Changeset Density: #{stats.median}"
	puts "Mode Changeset Density: #{stats.mode}"

	######################### OVERLAPPING CHANGESETS ############################################

end
