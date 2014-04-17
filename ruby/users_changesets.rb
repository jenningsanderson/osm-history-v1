
require 'mongo'
require 'optparse'
require 'json'
require 'time'
require 'georuby'
require 'geo_ruby/geojson'
require_relative 'write_geojson_featurecollection'


class UserWithChangesets

  @@query_bb = {:haiti =>
               {"type" => "Polygon",
                "coordinates" => [[ [-74.5532226563,17.8794313865],
                                  [-74.5532226563,19.9888363024],
                                  [-71.7297363281,19.9888363024],
                                  [-71.7297363281,17.8794313865],
                                  [-74.5532226563,17.8794313865] ]]},
              :philippines =>
                {"type" => "Polygon",
                 "coordinates" => [[ [120.0805664063, 9.3840321096],
                                  [120.0805664063, 13.9447299749],
                                  [126.6064453125, 13.9447299749],
                                  [126.6064453125, 9.3840321096],
                                  [120.0805664063, 9.3840321096] ]]}}

  @@query_time = {:haiti=>{
                    :start=>Time.new(2010,1,12),
                    :end  =>Time.new(2010,1,31)},

                  :philippines=>{
                    :start=>Time.new(2013,11,8),
                    :end  =>Time.new(2013,12,6)}
                 }

  attr_reader :uid, :properties

  def initialize(uid, db)
    @uid = uid
    @edits = []
    @db = db.to_sym
  end


  def get_changesets
    @changesets = COLL.find({:uid => @uid,
                             :closed_at=> {"$gt" => @@query_time[@db][:start], "$lt"=> @@query_time[@db][:end]},
                             :geometry => {"$geoWithin"=>
                                 {"$geometry" => @@query_bb[@db]}}},
                            {:fields=>['geometry']})
    @changeset_count = @changesets.count()
    @properties = {:uid => @uid, :changesets => @changeset_count}
    unless @changeset_count.zero?
      return true
    end
  end

  def process_geometries
    @changesets.each do |geom|
      unless geom['geometry'].nil?
        @edits << GeoRuby::SimpleFeatures::Geometry.from_geojson(geom['geometry'].to_json)
      end
    end
    unless @edits.empty?
      @bounding_box = GeoRuby::SimpleFeatures::GeometryCollection.from_geometries(@edits)
    end
  end

  def bounding_box
    envelope = @bounding_box.envelope #=> Will have to turn this into a valid geojson polygon

    GeoRuby::SimpleFeatures::Polygon.from_coordinates(
      [[[envelope.lower_corner.x, envelope.lower_corner.y],
        [envelope.lower_corner.x, envelope.upper_corner.y],
        [envelope.upper_corner.x, envelope.upper_corner.y],
        [envelope.upper_corner.x, envelope.lower_corner.y],
        [envelope.lower_corner.x, envelope.lower_corner.y]]] )
  end


end #class

if __FILE__ == $0
  options = OpenStruct.new
  opts = OptionParser.new do |opts|
    opts.banner = "Usage: ruby get_changesets.rb -d DATABASE  -f FILENAME[-l LIMIT]"
    opts.separator "\nSpecific options:"
    opts.on("-d", "--database Database Name",
            "Name of Database (Haiti, Philippines)"){|v| options.db = v }
    opts.on("-f", "--filename Output Filename",
            "Name of output file"){|v| options.filename = v }
    opts.on("-l", "--limit [LIMIT]",
            "[Optional] Limit of users to parse"){|v| options.limit = v.to_i }
    opts.on_tail("-h", "--help", "Show this message") do
      puts opts
      exit
    end
  end
  opts.parse!(ARGV)
  unless options.db
    puts opts
    exit
  end
  options.limit ||= 100000

  mongo_conn = Mongo::MongoClient.new('epic-analytics.cs.colorado.edu','27018')
  DB = mongo_conn[options.db]
  COLL = DB['changesets']

  query = COLL.distinct("uid").first(options.limit)
  uids = query.collect{|x| x.to_i}

  size = uids.count()

  puts "Processing #{size} Users"

  puts "Opening file for writing"

  file = GeoJSONWriter.new(options.filename)
  file.write_header

  cnt = 0

  uids.each_with_index do |uid, i|
    this_user = UserWithChangesets.new(uid, options.db)
    if this_user.get_changesets
      this_user.process_geometries
      feature = {:type=>"Feature", :geometry=>this_user.bounding_box, :properties=>this_user.properties}
      file.literal_write_feature(feature.to_json)
      cnt+=1
    end

    if (i%10).zero?
      puts "Processed #{i} of #{size}"
    end
  end
  file.write_footer
  puts "Found #{cnt} users"
end
