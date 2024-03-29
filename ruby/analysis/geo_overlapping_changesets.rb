#Standard Requirements
require 'json'
require 'time'
require 'csv'
require 'rsruby'

#Custom Requirements
require 'epic-geo'
require_relative '../osm_history_analysis'

class CalculateOverlaps
	attr_reader :user_overlaps, :factory, :dataset, :osm_driver

	def initialize(dataset, limit=1000)
		@dataset = dataset
		@osm_driver = OSMHistoryAnalysis.new(:local)
		@factory = @osm_driver.build_factory # Gives access to geofactory
	
		changesets_mongo = @osm_driver.connect_to_mongo(db=dataset, coll="changesets")

		@changesets = changesets_mongo.find(
				selector ={ :created_at=> {"$gt" => @osm_driver.dates[@dataset.to_sym][:event], 
										   "$lt" => @osm_driver.dates[@dataset.to_sym][:dw_end]},
						    :"geometry.type" => "Polygon"},
		        
		        opts ={ 	:limit=>limit,
		               		:fields=>['id','user','node_count', 'geometry'],
               				:sort=>'created_at'})
		puts "Found #{@changesets.count} results"
	end

	def calculate_overlaps_changesets
		#Build quick to access arrays
		changeset_ids   = []
		changeset_geoms = []
		@overlapping_changesets = {}

		#Build the reference arrays
		@changesets.each do |changeset|
			changeset_ids 	<< changeset['id']
			changeset_geoms << RGeo::GeoJSON.decode(changeset['geometry'].to_json, {:geo_factory=>factory, :json_parser=>:json})
		end
		puts "Finished building reference arrays, rewinding"

		@changesets.rewind!

		#Iterate through the changesets, remember it's going in order of time.
		# changeset_geoms.each_with_index do |this_geometry, index|

		# 	this_changeset = changeset_ids[index]

		# 	@overlapping_changesets[this_changeset] ||= []

		# 	changeset_geoms[index+1..-1].each_with_index do |conflict_geometry, offset|

		# 		if conflict_geometry.intersects? this_geometry
		# 			@overlapping_changesets[this_changeset] << changeset_ids[index+offset]
		# 		end
		# 	end

		# 	if (index%50).zero?
		# 		print "#{index}."
		# 	end
		# end

		num_overlaps = Array.new(changeset_geoms.length, 0)

		changeset_geoms.each_with_index do |this_geometry, index|

			changeset_geoms[index+1..-1].each_with_index do |conflict_geom, offset|

				if this_geometry.intersects? conflict_geom
					num_overlaps[index]+=1
				end
			end

			if (index%50).zero?
				print "#{index}."
			end
		end

		return num_overlaps

	end

	def calculate_overlaps_users
		#Build quick to access arrays
		changeset_ids   = []
		changeset_geoms = []
		users           = []
		overlaps        = {}

		#Build the reference arrays
		@changesets.each do |changeset|
			changeset_ids 	<< changeset['id']
			users 			<< changeset['user']
			changeset_geoms << RGeo::GeoJSON.decode(changeset['geometry'].to_json, {:geo_factory=>@osm_driver.geo_projected_factory, :json_parser=>:json})
		end
		puts "Finished building reference arrays, rewinding"

		@changesets.rewind!
		
		@user_overlaps = {}


		#Iterate through the changesets, remember it's going in order of time.
		changeset_geoms.each_with_index do |this_geometry, index|

			this_user 	  = users[index]
			#Initialize that user in the users hash if they don't exist yet
			@user_overlaps[this_user] ||= []

			changeset_geoms[index..-1].each_with_index do |conflict_geometry, offset|

				conflict_user = users[index+offset]
				
				#If it's the same user, don't process the count
				unless conflict_user == this_user
					if conflict_geometry.intersects? this_geometry
						@user_overlaps[this_user] << conflict_user
					end
				end
			end

			if (index%50).zero?
				print "#{index}."
			end
		end
	end

	def graph_it
		to_plot = @user_overlaps.map{|user,conflict_users| conflict_users.uniq.count}
		r = RSRuby.instance
		r.png("/Users/jenningsanderson/Dropbox/OSM_Behavioral_Analysis_CSCW/Images/user_changeset_geo_overlaps_probabilities#{@dataset}.png", :width=>800, :height=>400)
		r.hist(to_plot, :ylab=>"Normalized Frequency", :xlab=>"Number of overlapping users", :main=>"Overlapping User Changesets in #{@dataset.capitalize}")
		r.eval_R("dev.off()")
	end

	def write_to_csv
		CSV.open("csv_exports/user_changeset_geo_overlaps_#{@dataset}.csv",'w') do |csv|
			csv << ['user','overlaps', 'changesets']
			@user_overlaps.each do |user, conflict_users|
				csv << [user, conflict_users.uniq.count, conflict_users.count]
			end
		end
	end

	def write_changeset_csv
		CSV.open("csv_exports/changeset_geo_overlaps_#{@dataset}.csv",'w') do |csv|
			csv << ['changeset', 'num_overlaps']
			@overlapping_changesets.each do |changeset, overlaps_array|
				csv << [changeset, overlaps_array.count]
			end
		end
	end
end


#Find the overlapping changesets, currently counts all changesets, not just by user
# def calculate_overlap(res, country)
# 	puts "Working with #{changeset_geoms.count} changeset geometries"

# 	#Iterate through each of the geometries
# 	changeset_geoms.each_with_index do |geometry, index|

# 		this_id = changeset_ids[index]
# 		overlaps[this_id] ||= 0

# 		#Now check each of the geometries starting from this one up for overlap
# 		changeset_geoms[index..-1].each do |geo_test|
# 			if geometry.intersects? geo_test
# 				overlaps[this_id] += 1
# 			end
# 		end
		
# 	end




if $0 == __FILE__

	dataset = ARGV[0]

	if dataset.nil?
		puts "Please specify a dataset : (haiti | phil)"
		exit()
	end

	puts "Dataset: #{dataset}"

	overlaps = CalculateOverlaps.new(dataset, limit=nil)

	#puts "Calculating User Overlaps"
	#overlaps.calculate_overlaps_users

	puts "Calculating Changeset Overlaps"
	data = overlaps.calculate_overlaps_changesets

	stats = DescriptiveStatistics::Stats.new(data) #Compact to remove nil values
	puts "Mean Changeset Overlaps: #{stats.mean}"
	puts "Median Changeset Overlaps: #{stats.median}"
	puts "Mode Changeset Overlaps: #{stats.mode}"


	#puts "Showing Results:"
	#overlaps.user_overlaps.sort_by{|user,overlap| overlap.uniq.count}.reverse.each do |user, conflicts|
	#	puts "#{user} is overlapped by:  #{conflicts.uniq.count} users with #{conflicts.count} changesets"
	#end

	#overlaps.graph_it
	#overlaps.write_to_csv
	#overlaps.write_changeset_csv
end

