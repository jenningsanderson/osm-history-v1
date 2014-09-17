#
# This file is loaded by most of the analysis scripts, so global variables and the
# db connection can be well defined here
#

class OSMHistoryAnalysis
	require 'time'
	
	attr_reader :times, :geo_projected_factory

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

	#Method to return the relevant bounding boxes.
	def bounding_box(country)
		case country
		when :haiti
			return [[-74.5532226563,17.8794313865], [-71.7297363281,19.9888363024]]
		when :philippines
			return [120.0805664063,9.3840321096], [126.6064453125,13.9447299749]

		else
			return nil
		end
	end

	#Constructor: calls the query times function
    def initialize(mongo_dest)
		puts "Initialized OSMHistory"
		set_query_times

		case mongo_dest
		when :local
			@host = 'localhost'
			@port = 27017
		when :ea 
			@host = 'epic-analytics.cs.colorado.edu'
			@port = 27018
		end
    end

    #Require RGeo and build a factory for geo calculations and functions
    def build_factory
		require 'rgeo' #This is the same
		@geo_projected_factory = RGeo::Geographic.projected_factory(:projection_proj4=>'+proj=merc +lon_0=0 +k=1 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs <>')
	
		#TODO
		#Add different factories for better, more realistic calculations
	end

	def parse_date(date_to_parse)
		t = DateTime.parse(date_to_parse).to_time.utc
		#puts t
		return t
	end

    #Generic call for connecting to Mongo server with Error Handling, 
    #returns an instance of the collection for simple inline queries
    def connect_to_mongo(db='haiti',coll=nil, host=nil, port=nil)
    	require 'mongo'

    	host ||= @host
    	port ||= @port
    	
    	begin
	    	conn = Mongo::MongoClient.new(host,port)
			database = conn[db]
			unless coll.nil?
				collection = database[coll]
				puts "Connected to Mongo: #{db}.#{coll} successfully"
				puts "--------------------------------------------------------"
				return collection
			else
				puts "Connected to Mongo: #{db} successfully (no collection defined)"
				puts "--------------------------------------------------------"
				return database
			end
		rescue
			puts "Error connecting to Mongo"
			puts $!
		end
	end
end



class OSMAPI

	def initialize(baseurl)
		require 'net/http'
		require 'uri'
		require 'nokogiri'
		require 'json'

		@base_url = baseurl
	end

	def parse_response(response)
		a = {}
		response.children.each do |node|
			unless node.attributes.empty?
				node.children.each do |obj|
					obj.attributes.each do |k,v|
						a[v.name] = v.value
					end
				end
			end
		end
		return a
	end

	def hit_api(arg)
		begin
			uri = URI.parse(@base_url + arg.to_s)
			response = Net::HTTP.get(uri)
			xml = Nokogiri::XML.fragment(response)
			return parse_response(xml)
		rescue
			puts "Unsuccessful for user"
			puts $!
			return false
		end
	end
end

class LogFile
	require 'fileutils'
	def initialize(dir, filename)
		@lines = 0
		@filepath = "#{dir}/#{filename}_#{Time.now.to_s}.txt"
		FileUtils.mkdir_p(dir) unless File.exists?(dir)
		@openfile = File.open(@filepath, "wb")
	end

	def log(line)
		@lines +=1
		@openfile.write(line.to_s+"\n")
	end

	def close
		@openfile.close
		if @lines.zero?
			FileUtils.remove(@filepath)
		end
	end
end


if $0 == __FILE__
	puts "Running this file"

	changeset_x = 13501661
	user_x      = 751088

	#changeset_api = OSMAPI.new("http://api.openstreetmap.org/api/0.6/changeset/")
	#puts changeset_api.hit_api(changeset_x)
	
	user_api      = OSMAPI.new("http://api.openstreetmap.org/api/0.6/user/")
	puts user_api.hit_api(user_x)
	


end

