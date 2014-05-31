require 'json'
require 'epic-geo'
require 'mongo'
require 'time'
require 'csv'
require 'json'
require 'rsruby'

QUERY_TIME = {    :haiti=>{
					:event=>Time.new(2010,1,12,21,53,00),
                    :start=>Time.new(2010,01,12),
                    :end  =>Time.new(2010,02,12)},

                  :philippines=>{ 
                  	:event=>Time.new(2013,11,8),
                    :start=>Time.new(2013,11,8),
                    :end  =>Time.new(2013,12,8)}
               }
TOTAL_HOURS = ( QUERY_TIME[:haiti][:end].yday - QUERY_TIME[:haiti][:start].yday ) * 24 + 7




def write_user_contributions_by_day(res, filename)
	users = {}

	offset = res.first['created_at'].yday
	res.rewind!

	res.each do |changeset|
		#Define a spot for this user in the user hash
		this_user = changeset['user']
		users[this_user] ||= {:name=>changeset['user'],:node_count=>Array.new(31,0)}

		#Parse the date, it should be sorted already, so we should be able to take the day of the year
		unless changeset['node_count'].nil?
			users[this_user][:node_count][changeset['created_at'].yday - offset] += changeset['node_count']
		end
	end

	#Write the data out to a CSV to plot it in R later
	CSV.open("csv_exports/#{filename}",'w') do |csv|
		csv << ['User','NodeCount','DaysSinceEvent']

		users.sort_by{|user,info| info[:node_count].inject(:+)}.reverse.first(20).each_with_index do |(user, info), index|
			this_user = user
			info[:node_count].each_with_index do |cnt, index|
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

	distinct_users_per_hour.each_with_index do |val, i|
	#	puts "Hour: #{i} -> #{val}"
	end

	return distinct_users_per_hour

end

def hit_mongo(dataset)
  #CONN = Mongo::MongoClient.new #Defaults to localhost
  conn = Mongo::MongoClient.new('epic-analytics.cs.colorado.edu',27018)
  db = conn[dataset]
  coll = db['changesets']

  puts "Connected to Mongo"

	coll.find(
  		selector ={:created_at=> {"$gt" => QUERY_TIME[dataset.to_sym][:start], "$lt"=> QUERY_TIME[dataset.to_sym][:end]} },#,
                   #:node_count => {"$lt"=> 10000}},
            opts ={:limit=>nil,
                   :fields=>['user','node_count', 'created_at'],
                   :sort=>'created_at'})
end



if $0 == __FILE__

	res_phil = hit_mongo('philippines')
	res_haiti = hit_mongo('haiti')

	#write_user_contributions_by_day(res, "user_contributions_#{dataset}.csv")

	haiti_users_by_hour = get_user_count_by_hour(res_haiti, 'haiti')
	phil_users_by_hour  = get_user_count_by_hour(res_phil,  'philippines')

	#x_axis = (-166..TOTAL_HOURS-167).to_a
	x_axis = (1..TOTAL_HOURS).to_a

	#Plot it
	r = RSRuby.instance
	r.png("img_exports/users_editing_per_hour.png",:height=>600,:width=>800)
	r.plot( :x => x_axis, 
	    :y => phil_users_by_hour,
	    :xlab=>"Hours Elapsed Since Event",
	    :ylab=>"Number of Users Editing",
	    :col =>"blue",
	    :type=>'l'
	   )
	r.lines(:x => x_axis,
		:y => haiti_users_by_hour,
		:col => "red"
	   )
	#Add the event, if applicable:
	#r.eval_R %Q{ text(0,50,"Event", 
	#			 pos = 2, cex = 1.5, srt = 90)

	#}
	#r.abline(:v=>0)
	#Add the legend
	r.eval_R %Q{ legend(550,80, 					 # places a legend at the appropriate place 
				 c("Philippines","Haiti"),           # puts text in the legend 
                 lty=c(1,1), 				 		 # gives the legend appropriate symbols (lines)
                 lwd=c(2.5,2.5),col=c("blue","red"), # gives the legend lines the correct color and width
				 cex=1.5) 							 # Changes the font size 
	}
	r.eval_R('dev.off()')

end






