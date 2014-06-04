require 'json'
require 'mongo'
require 'time'
require 'date'
require 'csv'
require 'json'
require 'rsruby'

require 'epic-geo'
require_relative 'osm_history_analysis'

class NodesPerDay

	attr_reader :osm_data, :days

	def initialize(dataset='haiti')
		@osm_data = OSMHistoryAnalysis.new

		@dataset=dataset

		conn = Mongo::MongoClient.new('epic-analytics.cs.colorado.edu',27018)
  		db = conn[@dataset]
  		@coll = db['changesets']

  		@days = []
	end

	def iterate_through_days(start_date, days=31)
		days.times.each_with_index do |times, i|
			open = start_date + (60*60*24*i)
			close = start_date + (60*60*24*(i+1))

			nodes = hit_mongo(start_time=open, end_time=close).collect{|changeset| changeset["node_count"]}.compact.inject(:+) || 0
		
			puts "#{i}: Between #{open}-#{close}: #{nodes} nodes were edited"

			@days[i] = nodes
		end
	end

	def hit_mongo(start_time, end_time)
	@coll.find(
  		selector ={:created_at=> {"$gte" => start_time, "$lte"=> end_time }},
            opts ={:limit=>nil,
                   :fields=>['node_count']
               })
	end

end

def plot_the_bar_comparison(dat_1, dat_2, offset)
	r = RSRuby.instance
	r.png("/Users/jenningsanderson/Dropbox/OSM_Behavioral_Analysis_CSCW/Images/nodes_per_day.png",:height=>600,:width=>800)

	r.eval_R %Q{
		height <- rbind(c(#{dat_1.join(',')}), c(#{dat_2.join(',')}))
		
		barplot(	height,
					width=1,
				 	beside=TRUE,
				 	main="Nodes Edited Each Day since Event", 
				 	xlab="Days Since Event",
				 	ylab="Nodes Edited",
				 	names.arg=seq(-7,30),
				 	axisnames=TRUE,
				 	cex.main=2, 
				 	cex.axis=1.2, 
				 	cex.lab=1.2
				 )
		abline(v=24, col="red")

	}

	r.eval_R %Q{ text(24,150000,"Event",
				 pos = 2, cex = 1.5, srt = 90)}

	#Add the legend
	r.eval_R %Q{ legend("topright", 					 # places a legend at the appropriate place 
	 			 c("Philippines","Haiti"),           # puts text in the legend 
                  pch=c(15,15), 				 		 # gives the legend appropriate symbols (lines)
                  col=c("gray","black"), # gives the legend lines the correct color and width
	 			  cex=1.5) 							 # Changes the font size 
	}

	r.eval_R("dev.off()")

	print r.height
	
	

end



if $0 == __FILE__
	puts "Running Nodes Edited By User"

	puts "Calling for Haiti"
	haiti = NodesPerDay.new(dataset='haiti')
	haiti.iterate_through_days(start_date = haiti.osm_data.times[:haiti][:one_week_before], days=38)

	puts "Calling for Philippines"
	phil = NodesPerDay.new(dataset='philippines')
	phil.iterate_through_days(start_Date = phil.osm_data.times[:philippines][:one_week_before], days=38)
	
	puts "Calling the Plot function"
	plot_the_bar_comparison(haiti.days, phil.days, 7)


end






