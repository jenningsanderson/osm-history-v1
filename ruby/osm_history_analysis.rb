require 'mongo'

#This is the main class for global variables & common functions to the analysis
class OSMHistoryAnalysis
	attr_reader :coll, :times

	#Set the most common times for querying the database 
	def set_query_times
		@times = {    
			:haiti=>{
				:one_week_before=>	Time.new(2010,01,5),
				:event			=>	Time.new(2010,01,12),
				:one_week_after	=>	Time.new(2010,01,19),
				:dw_end			=>	Time.new(2010,02,12)
			},

			:philippines=>{ 
				:one_week_before=>	Time.new(2013,11,1),
				:event			=>	Time.new(2013,11,8),
				:one_week_after	=>	Time.new(2013,11,15),
				:dw_end			=>	Time.new(2013,12,8)
			}
		}
	end 

	#Constructor: calls the query times function
    def initialize
		puts "Initialized OSMHistory, initilialized to epic-server"
		set_query_times
    end

    #Generic call for connecting to Mongo server with Error Handling, 
    #returns an instance of the collection for simple inline queries
    def connect_to_mongo(db='haiti',coll='nodes', host=nil, port=nil)
    	
    	host ||= 'epic-analytics.cs.colorado.edu' 
    	port ||= 27018
    	
    	begin
	    	conn = Mongo::MongoClient.new(host,port)
			db = conn[db]
			@coll = db[coll]
			puts "Connected to Mongo"
		rescue
			puts "Error connecting to Mongo"
			puts $!
		end
		return @coll
	end
end