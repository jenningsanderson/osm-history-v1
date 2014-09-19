require 'epic-geo'
require 'time'
require 'csv'
require 'rsruby'

#Export a CSV of User Contributions by day (By User)
def write_user_contributions_by_day(res, filename) #This must be sorted by created_at date.
	users = {}

	offset = res.first['created_at'].yday #The first day of changesets
	res.rewind!

	res.each do |changeset|

		#Define a spot for this user in the user hash
		this_user = changeset['user']
		users[this_user] ||= Array.new(31,0)
			                 
		#Parse the date, it should be sorted already, so we should be able to take the day of the year
		unless changeset['node_count'].nil? #If so, we have an error
			users[this_user][changeset['created_at'].yday - offset] += changeset['node_count']
		else
			puts "Changeset #{changeset["id"]} didn't have a node_count"
		end
	end

	#Write the data out to a CSV to plot it in R later
	CSV.open("../../exports/csv/confirmation/#{filename}",'w') do |csv|
		csv << ['User','NodeCount','DaysSinceEvent']

		users.sort_by{ |user, info| info.inject(:+) }.reverse.each_with_index do |(user, info), index|
			this_user = user
			
			info.each_with_index do |cnt, index|
				csv << [user, cnt, index+1]
			end
		end
	end #close the csv
end






def get_user_count_by_hour(res, dataset)

	offset = QUERY_TIME[dataset.to_sym][:start].yday
	puts "Offset: #{offset}"
	res.rewind!

	users_per_hour = {}

	res.each do |changeset|
		this_hour = (changeset['created_at'].yday - offset) * 24 + changeset['created_at'].hour
		users_per_hour[this_hour] ||= []
		users_per_hour[this_hour] << changeset['user']
	end

	distinct_users_per_hour = Array.new(TOTAL_HOURS,0)

	users_per_hour.each do |hour,users_array|
		#puts "#{hour}: #{users_array.uniq.count}"
		distinct_users_per_hour[hour] += users_array.uniq.count
	end

	#distinct_users_per_hour.each_with_index do |val, i|
		#puts "Hour: #{i} -> #{val}"
	#end

	puts distinct_users_per_hour.sort.reverse

	return distinct_users_per_hour

end




#############################################################################
#######################          RUNTIME        #############################
#############################################################################

if $0 == __FILE__
	require_relative '../osm_history_analysis'

	#Open connections
	osm_driver = OSMHistoryAnalysis.new(:local)
	
	haiti = osm_driver.connect_to_mongo(db='haiti', coll='changesets')
	phil  = osm_driver.connect_to_mongo(db='phil',  coll='changesets')



	############################   BY DAY CALCULATIONS   ####################################

	#Calcualte for Haiti by day:
	country = 'haiti'
	haiti_changesets = haiti.find(
		{
			:created_at => {'$gt' => osm_driver.dates[:haiti][:event],
							'$lt' => osm_driver.dates[:haiti][:dw_end]
						   },
			:node_count => {'$ne' => nil}
		})

	puts "Found #{haiti_changesets.count} results"

	puts haiti_changesets.collect{|entry| entry["node_count"]}.inject(:+)



	# write_user_contributions_by_day(haiti_changesets, "haiti_user_nodes_by_day_all.csv")


	# #Calculate for Phil by day:
	# phil_changesets = phil.find(
	# 	{
	# 		:created_at => {'$gt' => osm_driver.dates[:philippines][:event],
	# 						'$lt' => osm_driver.dates[:philippines][:dw_end]
	# 					   },
	# 		:node_count => {'$ne' => nil}
	# 	})

	# puts "Found #{phil_changesets.count} results"

	# write_user_contributions_by_day(phil_changesets, "phil_user_nodes_by_day_all.csv") 



	#############################  BY HOUR CALCULATIONS   ################################


	# get_user_count_by_hour(res_phil, 'philippines')

	#res_haiti = hit_mongo('haiti')
	#get_user_count_by_hour(res_haiti, 'haiti')

	# res_haiti = hit_mongo('haiti')

	# #write_user_contributions_by_day(res, "user_contributions_#{dataset}.csv")

	# haiti_users_by_hour = get_user_count_by_hour(res_haiti, 'haiti')
	# phil_users_by_hour  = get_user_count_by_hour(res_phil,  'philippines')

	# #x_axis = (-166..TOTAL_HOURS-167).to_a
	# x_axis = (1..TOTAL_HOURS).to_a

	# #Plot it
	# r = RSRuby.instance
	# r.png("img_exports/users_editing_per_hour.png",:height=>600,:width=>800)
	# r.plot( :x => x_axis, 
	#     :y => phil_users_by_hour,
	#     :xlab=>"Hours Elapsed Since Event",
	#     :ylab=>"Number of Users Editing",
	#     :col =>"blue",
	#     :type=>'l'
	#    )
	# r.lines(:x => x_axis,
	# 	:y => haiti_users_by_hour,
	# 	:col => "red"
	#    )
	#Add the event, if applicable:
	#r.eval_R %Q{ text(0,50,"Event", 
	#			 pos = 2, cex = 1.5, srt = 90)

	#}
	#r.abline(:v=>0)
	#Add the legend
	# r.eval_R %Q{ legend(550,80, 					 # places a legend at the appropriate place 
	# 			 c("Philippines","Haiti"),           # puts text in the legend 
 #                 lty=c(1,1), 				 		 # gives the legend appropriate symbols (lines)
 #                 lwd=c(2.5,2.5),col=c("blue","red"), # gives the legend lines the correct color and width
	# 			 cex=1.5) 							 # Changes the font size 
	# }
	# r.eval_R('dev.off()')

end






