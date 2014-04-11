
require 'mongo'
require 'net/http'
require 'uri'
require 'nokogiri'
require 'json'
require 'time'
require 'optparse'

class OSMChangeset

  @@url_base = "http://api.openstreetmap.org/api/0.6/changeset/"

  attr_reader :changeset

  def initialize(id, type)
    @changeid = id
    objects_query = COLL.find({"properties.changeset"=>id})
    objects = objects_query.collect{|x| x["id"]}
    @changeset = {type[0..-2]+'_count' => objects.size, type=>objects }
  end

  def hit_api
    begin
      uri = URI.parse(@@url_base+@changeid.to_s)
      response = Net::HTTP.get(uri)
      @changeset_xml = Nokogiri::XML.fragment(response)
    rescue
      puts "Unsuccessful for changeset: #{@changeid}"
      puts $!
      return false
    end
  end

  def parse_response
    @changeset_xml.children.each do |node|
      unless node.attributes.empty?
        node.children.each do |obj|
          obj.attributes.each do |k,v|
            @changeset[v.name]=v.value
          end
        end
      end
    end
  end

  def extract_bounding_box
    ll = [ @changeset["min_lon"].to_f, @changeset["min_lat"].to_f ]
    lr = [ @changeset["max_lon"].to_f, @changeset["min_lat"].to_f ]
    ur = [ @changeset["max_lon"].to_f, @changeset["max_lat"].to_f ]
    ul = [ @changeset["min_lon"].to_f, @changeset["max_lat"].to_f ]

    coords = [ll,ul, ur, lr, ll]

    @changeset[:geometry] = { :type=>"Polygon", :coordinates=>[coords]}
  end

  def fix_types
    open = Time.parse @changeset["created_at"]
    close = Time.parse @changeset["closed_at"]
    @changeset["created_at"] = open
    @changeset["closed_at"] = close

    @changeset["id"] = @changeset["id"].to_i
    @changeset["uid"] = @changeset["uid"].to_i
  end

  def insert_to_mongo
    DB['changesets'].update({"id" => @changeset["id"]}, {'$set' => @changeset}, opts={:upsert=>true})
  end

end


if __FILE__ == $0
  options = OpenStruct.new
  opts = OptionParser.new do |opts|
    opts.banner = "Usage: ruby get_changesets.rb -d DATABASE -c COLLECTION  [-l LIMIT]"
    opts.separator "\nSpecific options:"

    opts.on("-d", "--database Database Name",
            "Name of Database (Haiti, Philippines)"){|v| options.db = v }
    opts.on("-c", "--Collection Collection Name",
            "Type of OSM object (nodes, ways, relations)"){|v| options.coll = v }
    opts.on("-l", "--limit [LIMIT]",
            "[Optional] Limit of objects to parse"){|v|
              v ||= 10000000
              options.limit = v.to_i }
    opts.on_tail("-h", "--help", "Show this message") do
      puts opts
      exit
    end
  end
  opts.parse!(ARGV)
  unless options.db and options.coll
    puts opts
    exit
  end

  mongo_conn = Mongo::MongoClient.new('epic-analytics.cs.colorado.edu','27018')
  DB = mongo_conn[options.db]
  COLL = DB[options.coll]

  query = COLL.distinct("properties.changeset").first(options.limit)
  changesets = query.collect{|x| x.to_i}

  changesets.sort! #safety measure (Incase the import crashes...)

  size = changesets.count()

  puts "Processing #{size} changesets"

  changesets.each_with_index do |changeset, i|
    this_changeset = OSMChangeset.new(changeset, options.coll)
    if this_changeset.hit_api
      this_changeset.parse_response
      this_changeset.extract_bounding_box
      this_changeset.fix_types
      this_changeset.insert_to_mongo
    end

    if (i%10).zero?
      print "Processed #{i} of #{size}"
    end
  end
end
