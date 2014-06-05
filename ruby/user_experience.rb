#Require system stuff
require 'json'
require 'mongo'
require 'time'

#Require custom classes
require 'epic-geo'
require_relative 'osm_history_analysis'


class UserExperience

	def initialize(dataset)
		@osm_data = OSMHistoryAnalysis.new
		@dataset = dataset

		haiti_node_users = []
		haiti_users_users = []
	end

	def get_distinct_users_in_dw
		start_date = @osm_data.times[@dataset.to_sym][:event]
		end_date = @osm_data.times[@dataset.to_sym][:dw_end]

		@distinct_users_in_dw = get_distinct_users(start_date, end_date)
		puts "Distinct Users who joined During Disaster Window", @distinct_users_in_dw.size
	end

	def get_distinct_users_in_dw_from_nodes
		start_date = @osm_data.times[@dataset.to_sym][:event]
		end_date = @osm_data.times[@dataset.to_sym][:dw_end]

		@distinct_users_in_dw_from_nodes = get_distinct_node_users(start_date, end_date)
		puts "Distinct Users who EDITED A NODE During Disaster Window", @distinct_users_in_dw_from_nodes.size
	end

	def all_distinct_users
		@distinct_users_in_users = get_distinct_users(Time.new(2000-01-01),Time.now)
		puts @distinct_users_in_users.size
	end

	def who_is_missing
		puts "Find who is missing"
		#print @distinct_users_in_dw_from_nodes
		puts "\n\n\n"
		#print @distinct_users_in_users
		missing = (@distinct_users_in_dw_from_nodes - @distinct_users_in_users)
		puts "This many users show up in nodes during DW, but not users collection: ", missing.size

		print missing

	end

	def get_distinct_users(start_date, end_date)
		coll = @osm_data.connect_to_mongo(dataset=@dataset, coll='users')
		coll.distinct('uid',{'joiningdate'=>{"$gt" => start_date, "$lt"=> end_date}}).collect{|num| num.to_i}
	end

	def get_distinct_node_users(start_date, end_date)
		coll = @osm_data.connect_to_mongo(dataset=@dataset, coll='nodes')
		coll.distinct('properties.uid',{'date'=>{"$gt" => start_date, "$lt"=> end_date}})
	end
end


if $0 == __FILE__

	#Calculate for Haiti
	phil = UserExperience.new('philippines')
	phil.get_distinct_users_in_dw
	phil.get_distinct_users_in_dw_from_nodes
	phil.all_distinct_users
	phil.who_is_missing

	#So who are the users that edited in the disaster window that do not exist in the nodes collection?
end

