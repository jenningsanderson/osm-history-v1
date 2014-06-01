#Require system stuff
require 'json'
require 'mongo'
require 'rsruby'

#Require custom classes
require 'epic-geo'
require_relative 'osm_history_analysis'

class EditsPerUser
	attr_reader :users

	def initialize(db='nil')
		@users = {}
		@dataset = db
		@osm_data = OSMHistoryAnalysis.new
	end

	def hit_mongo(limit=nil)
		@coll = @osm_data.connect_to_mongo(dataset=@dataset, coll='nodes')

		@res = @coll.find( selector = {'date'=> {"$gt" => @osm_data.times[dataset.to_sym][:event], "$lt"=> @osm_data.times[dataset.to_sym][:dw_end]}},
							opts    = {:fields=>['properties.user'],
									   :limit =>limit	}
						 )
	end

	def quantify_edits
		@res.each_with_index do |changeset, index|
			this_user = changeset['properties']['user']
			
			@users[this_user] ||= 0
			@users[this_user] += 1

			if (index%10000).zero?
				print "#{index}.."
			end
		end
	end

	def graph_it
		puts "Calling R"
		r = RSRuby.instance

		puts "R Summary Statistics:"
		puts "Median Edits Per User: #{r.median(@users.values)}"
		puts "Average Edits Per user: #{r.mean(@users.values)}"

		r.png("img_exports/#{@dataset}_edits_per_user.png", :width=>800, :height=>600)
		r.barplot(:height=>(@users.values.sort.reverse), :log=>'y',:ylab=>"Number of Edits", :xlab=>"Users", :main=>"#{@dataset.capitalize}: Number of Edits per User")
		r.eval_R "dev.off()"
		puts "Finished Writing Graph"
	end
end


if $0 == __FILE__
	puts "Generating graph for edits / user"

	db = ARGV[0]

	if db.nil?
		puts "Please specify a Country:"
		puts "ruby edits_per_user_visual.rb <haiti, philippines>"
		exit(1)
	end

	puts "Calling Graph/Edits for #{db}"

	users = EditsPerUser.new(db=db)

	users.hit_mongo(limit=nil)
	users.quantify_edits
	
	puts "Total Edits: #{users.users.values.inject(:+)}"
	puts "Total Users counted: #{users.users.count}"

	users.graph_it

end