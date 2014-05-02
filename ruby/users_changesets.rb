require 'mongo'
require 'optparse'
require 'json'
require 'time'
require 'georuby'
require 'geo_ruby/geojson'
require 'geo_ruby/kml'
require_relative 'write_geojson_featurecollection'
require_relative 'kml_writer_helper'
require 'rgeo'
require 'rgeo/geo_json'

class UserWithChangesets
  '''Defining the characteristics of each dataset'''

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
                    :start=>Time.new(2010,1,8),
                    :end  =>Time.new(2010,2,12)},

                  :philippines=>{
                    :start=>Time.new(2013,11,6),
                    :end  =>Time.new(2013,12,6)}
                 }

  attr_reader :uid, :properties, :edits, :changesets, :changeset_count

  def initialize(uid, db)
    @uid = uid
    @edits = []
    @db = db.to_sym
  end

  def get_changesets
    @changesets = COLL.find({:uid => @uid,
                             :closed_at=> {"$gt" => @@query_time[@db][:start], "$lt"=> @@query_time[@db][:end]},
                             :area => {"$gt" => 1, "$lt"=>1000},
                             :node_density => {'$gt' => 1 },
                             :geometry => {"$geoWithin"=>
                                 {"$geometry" => @@query_bb[@db]}}},
                            {:fields=>['geometry', 'id', 'closed_at', 'created_at', 'user', 'node_count']})
    @changeset_count = @changesets.count()
    unless @changeset_count.zero?
      @properties = {:uid => @uid, :changesets => @changeset_count, :user => @changesets.first['user']}
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
    @changesets.rewind! #Reset the cursor
  end

  def bounding_box_envelope
    envelope = @bounding_box.envelope #=> Will have to turn this into a valid geojson polygon

    GeoRuby::SimpleFeatures::Polygon.from_coordinates(
      [[[envelope.lower_corner.x, envelope.lower_corner.y],
        [envelope.lower_corner.x, envelope.upper_corner.y],
        [envelope.upper_corner.x, envelope.upper_corner.y],
        [envelope.upper_corner.x, envelope.lower_corner.y],
        [envelope.lower_corner.x, envelope.lower_corner.y]]] )
  end

  def changesets_geometries
    @bounding_box
  end
end #class

def write_user_bounding_envelopes(filename, cursor, db)
  puts "Opening file for writing"
  file = GeoJSONWriter.new(filename)
  file.write_header
  cnt = 0
  cursor.each_with_index do |uid, i|
    this_user = UserWithChangesets.new(uid, db)
    if this_user.get_changesets
      this_user.process_geometries
      feature = {:type=>"Feature", :geometry=>this_user.bounding_box_envelope, :properties=>this_user.properties}
      file.literal_write_feature(feature.to_json)
      cnt+=1
    end
    if (i%10).zero?
      puts "Processed #{i} users"
    end
  end
  file.write_footer
  puts "Found #{cnt} users"
end

def write_user_changesets(filename, cursor, db)
  puts "Opening file for writing"
  file = GeoJSONWriter.new(filename)
  file.write_header
  cnt = 0
  cursor.each_with_index do |uid, i|
    this_user = UserWithChangesets.new(uid, db)
    if this_user.get_changesets
      this_user.process_geometries
      this_user.changesets_geometries.each do |geom|
        feature = {:type=>"Feature", :geometry=>geom, :properties=>this_user.properties}
        file.literal_write_feature(feature.to_json)
      end
      cnt+=1
    end
    if (i%10).zero?
      puts "Processed #{i} users"
    end
  end
  file.write_footer
  puts "Found #{cnt} users"
end

def write_changeset_kml(filename, cursor, db, title='KML FILE')
  puts "Writing user changesets to KML"

  file = KMLAuthor.new(filename)
  file.write_header(title)
  file.generate_random_styles(100)

  cnt = 0
  cursor.each_with_index do |uid, i|
    this_user = UserWithChangesets.new(uid, db)

    if this_user.get_changesets
      cnt+=1
      this_user.process_geometries

      this_folder = {:name=>this_user.properties[:user], :features=>[]}

      random = rand(100) #Set a random color for this user

      this_user.changesets.each_with_index do |changeset, j|
        this_folder[:features] << {
          :name => changeset["id"],
          :geometry => this_user.edits[j],
          :time => changeset['closed_at'],
          :style =>"#r_style_#{random}",
          :desc => %Q{Time:  #{changeset['closed_at']}
                      User:  #{changeset['user']}
                      Nodes: #{changeset['node_count']}}
        }
      end
      file.write_folder(this_folder)
    end
    if (i%10).zero?
      puts "Processed #{i} users, found #{cnt} users to match description"
    end
  end
  file.write_footer
  puts "Found #{cnt} users"
end

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
    opts.on("-t", "--title [TITLE]",
            "[Optional] Give a title for the KML document"){|v| options.title = v }
    opts.on_tail("-h", "--help", "Show this message") do
      puts opts
      exit
    end
  end
  opts.parse!(ARGV)
  unless options.db and options.filename
    puts opts
    exit
  end
  options.limit ||= 100000

  #mongo_conn = Mongo::MongoClient.new('epic-analytics.cs.colorado.edu','27018')
  mongo_conn = Mongo::MongoClient.new #Defaults to localhost
  DB = mongo_conn[options.db]
  COLL = DB['changesets']


  query = COLL.find(selector = {},opts = {:limit=>options.limit})

  '''Write the users to a kml'''
  query = COLL.distinct("uid").first(options.limit)
  uids = query.collect{|x| x.to_i}
  size = uids.count()
  puts "Processing #{size} Users"

  #write_changeset_kml(options.filename, uids, options.db, title=options.title)

  #Find user contributions
  users = []
  query.each do |uid|
    user = UserWithChangesets.new(uid, options.db)
    user.get_changesets
    users << user
  end

  sorted = users.sort_by { |user| user.changeset_count}

  sorted.reverse!.first(10).each do |user|
    puts "#{user.properties[:user]}: #{user.changeset_count}"
  end



end




































'''Deprecated FileIO'''
#write_user_bounding_envelopes(options.filename, uids, options.db)
#write_user_changesets(options.filename, uids, options.db)

'''Deprecated GeoData Addition'''
#Define a factory for making our polygons
#factory = RGeo::Geographic.projected_factory(:projection_proj4 =>
#'+proj=merc +lon_0=0 +k=1 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs')
# query.each_with_index do |changeset, i|
#   unless changeset["geometry"].nil?
#     if changeset["geometry"]["type"] == "Polygon"
#       geo_obj = RGeo::GeoJSON.decode(changeset["geometry"].to_json, {:geo_factory=>factory, :json_parser=>:json})
#       area = geo_obj.area
#       unless area.nil?
#         area /= 1000000
#         unless changeset['node_count'].nil?
#           node_density = changeset['node_count'] / area
#         end
#       end
#     end
#     area ||= 1
#     node_density ||= 1
#     COLL.update({'_id' => changeset["_id"]}, {'$set' => {:area => area, :node_density=>node_density}})
#   end
#   if (i%1000).zero?
#     puts "Processed #{i} changesets"
#   end
# end
