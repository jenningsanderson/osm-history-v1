'''
This script uses Ruby to interface with Mongo to extract data and then uses the rsruby wrapper
for R to plot the data -- as far as visualizing data with Ruby, this is probably the strongest
method.
'''

require 'mongo'
require 'rsruby'
require 'time'

#rsruby follows a singleton design pattern, so we initialize with an instance, not 'new'
r = RSRuby.instance

#Connect to Mongo --> Choose your db here
CONN = Mongo::MongoClient.new('epic-analytics.cs.colorado.edu', 27018)
DB = CONN['philippines']
COLL = DB['changesets']

#Make a new hash for getting data from DB, use r functions to format it properly
date_hist = {}
COLL.find({},{}).each do |changeset|
	#puts changeset.inspect
	time = r.as_Date(changeset['created_at'].iso8601)
	date_hist[time] ||= []
	if changeset['node_count'].to_i < 10000
		date_hist[time] << changeset['node_count'].to_i
	end
end

puts "Done with cursor"

#Now break the data into arrays (sorted)
x_vals = []
y_vals = []

date_hist.sort_by {|key, value| key}.each do |k,v|
 	x_vals << k
 	y_vals << v.inject{ |sum, el| sum + el }.to_f / v.size #This is why Ruby is the best (Get the avg)
end

#puts r.eval_R "class(as.Date(#{date_hist.keys[0]},origin=\"1970,01-01\")"
puts "Done with prepping"

#Set the r variable for dates for the x axis.
r.assign('dates',r.as_Date(x_vals, :origin=>"1970-01-01", :format=>'%m/%d/%Y'))

r.png("avg_changeset_size_per_day_phil.png",:height=>600,:width=>800)
r.plot({:x=>x_vals,:y=>y_vals, :ylab=>'Average Nodes per changeset',:xaxt=>'n',:xlab=>"Day"})
r.eval_R "axis.Date(1, as.Date(dates, origin=\"1960-10-01\"), format='%m/%d/%Y')"
r.eval_R "dev.off()"


