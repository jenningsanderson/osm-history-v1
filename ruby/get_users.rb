
require 'mongo'
require 'net/http'
require 'uri'
require 'nokogiri'
require 'json'
require 'time'

class OSMChangeset

  @@url_base = "http://api.openstreetmap.org/api/0.6/changeset/"

  attr_reader :changeid, :changeset

  def initialize(id)
    @changeid = id
    @changeset = {}
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

    @changeset[:geometry] = { :type=>"Polygon", :coordinates=>[coords]}.to_json
  end

  def parse_date
    open = Time.parse @changeset["created_at"]
    close = Time.parse @changeset["closed_at"]

    @changeset["created_at"] = open
    @changeset["closed_at"] = close
  end

  def insert_to_mongo
    DB['changesets'].insert(@changeset.to_json)
  end

end


if __FILE__ == $0
  puts "Running User script"
  db = 'haiti'

  mongo_conn = Mongo::MongoClient.new('epic-analytics.cs.colorado.edu','27018')
  DB = mongo_conn[db]
  COLL = DB['nodes']

  nodes_query = COLL.find({},
                    opts={:fields=>["properties.changeset"],
                          :limit=>1})

  changesets = nodes_query.collect{ |x| x["properties"]["changeset"]}

  changesets.each do |changeset|
    this_changeset = OSMChangeset.new(changeset)

    if this_changeset.hit_api
      this_changeset.parse_response
      this_changeset.extract_bounding_box
      this_changeset.parse_date
      this_changeset.changeset.each do |k,v|
        puts "#{k}.......#{v}"
      end

    end
  end
end
