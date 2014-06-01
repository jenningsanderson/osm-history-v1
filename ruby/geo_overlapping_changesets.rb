require 'json'
require 'epic-geo'
require 'mongo'
require 'time'
require 'csv'
require 'json'
require 'rsruby'
require 'rgeo/geo_json'
require 'rgeo'

QUERY_TIME = {    :haiti=>{
					:event=>Time.new(2010,1,12),
                    :start=>Time.new(2010,01,12),
                    :end  =>Time.new(2010,02,12)},

                  :philippines=>{ 
                  	:event=>Time.new(2013,11,8),
                    :start=>Time.new(2013,11,8),
                    :end  =>Time.new(2013,12,8)}
               }
#TOTAL_HOURS = ( QUERY_TIME[:haiti][:end].yday - QUERY_TIME[:haiti][:start].yday ) * 24 + 7
GEO_PROJECTED_FACTORY = RGeo::Geographic.projected_factory(:projection_proj4=>'+proj=merc +lon_0=0 +k=1 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs <>')


def hit_mongo(dataset, limit)
  #CONN = Mongo::MongoClient.new #Defaults to localhost
  conn = Mongo::MongoClient.new('epic-analytics.cs.colorado.edu',27018)
  db = conn[dataset]
  coll = db['changesets']

  puts "Connected to Mongo"

	coll.find(
  		selector ={:created_at=> {"$gt" => QUERY_TIME[dataset.to_sym][:start], "$lt"=> QUERY_TIME[dataset.to_sym][:end]},
                   :area => {"$lt"=> 10000}},
            opts ={:limit=>limit,
                   :fields=>['id','user','node_count', 'geometry'],
                   :sort=>'created_at'})
end


changeset_overlaps = {}

#Find the overlapping changesets, currently counts all changesets, not just by user
def calculate_overlap(res, country)

	changeset_ids   = []
	changeset_geoms = []
	overlaps        = {}

	#Build the two arrays
	res.each do |changeset|
		changeset_ids << changeset['id']
		changeset_geoms << RGeo::GeoJSON.decode(changeset['geometry'].to_json, {:geo_factory=>GEO_PROJECTED_FACTORY, :json_parser=>:json})
	end

	puts "Working with #{changeset_geoms.count} changeset geometries"

	#Iterate through each of the geometries
	changeset_geoms.each_with_index do |geometry, index|

		this_id = changeset_ids[index]
		overlaps[this_id] ||= 0

		#Now check each of the geometries starting from this one up for overlap
		changeset_geoms[index..-1].each do |geo_test|
			if geometry.intersects? geo_test
				overlaps[this_id] += 1
			end
		end
		if (index%50).zero?
			print "#{index}."
		end
	end

	to_plot = []

	#Now show the results
	# overlaps.sort_by{|id,val| val}.reverse.each do |changeset_id, overlaps|
	# 	#puts "#{changeset_id} is overlapped by:  #{overlaps}"
	# 	to_plot << overlaps
	# end

	to_plot = overlaps.map{|id,val| val}

	r = RSRuby.instance
	r.png("img_exports/changeset_geo_overlaps_#{country}.png", :width=>800, :height=>400)
	r.hist(r.log(to_plot,:base=>10), :xlab=>"Number of Changesets", :ylab=>"Number of overlapping changesets", :main=>"Overlapping Changesets in #{country}")
	r.eval_R("dev.off()")

end



if $0 == __FILE__

	res_phil = hit_mongo('philippines', nil)
	res_haiti = hit_mongo('haiti',nil)

	calculate_overlap(res_haiti, "Haiti")
	calculate_overlap(res_phil, "Philippines")


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
	# #Add the event, if applicable:
	# #r.eval_R %Q{ text(0,50,"Event", 
	# #			 pos = 2, cex = 1.5, srt = 90)

	# #}
	# #r.abline(:v=>0)
	# #Add the legend
	# r.eval_R %Q{ legend(550,80, 					 # places a legend at the appropriate place 
	# 			 c("Philippines","Haiti"),           # puts text in the legend 
 #                 lty=c(1,1), 				 		 # gives the legend appropriate symbols (lines)
 #                 lwd=c(2.5,2.5),col=c("blue","red"), # gives the legend lines the correct color and width
	# 			 cex=1.5) 							 # Changes the font size 
	# }
	# r.eval_R('dev.off()')

end






