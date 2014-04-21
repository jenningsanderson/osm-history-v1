
require 'mongo'
require 'optparse'
require 'json'
require 'time'
require 'georuby'
require 'geo_ruby/geojson'
require 'geo_ruby/kml'
require_relative 'write_geojson_featurecollection'
require_relative 'kml_writer_helper'

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
                    :start=>Time.new(2006,1,0),
                    :end  =>Time.new(2010,1,31)},

                  :philippines=>{
                    :start=>Time.new(2006,1,8),
                    :end  =>Time.new(2013,12,6)}
                 }

  attr_reader :uid, :properties, :edits, :changesets

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
                            {:fields=>['geometry', 'id', 'closed_at', 'created_at', 'user', 'node_count']})
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
  puts "Attempting to write a kml file... this is new"

  file = KMLAuthor.new(filename)
  file.write_header(title)
  file.generate_random_styles(100)

  cnt = 0
  cursor.each_with_index do |uid, i|
    this_user = UserWithChangesets.new(uid, db)

    if this_user.get_changesets
      cnt+=1
      this_user.process_geometries

      this_folder = {:name=>uid, :features=>[]}

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
      puts "Processed #{i} users"
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

  mongo_conn = Mongo::MongoClient.new('epic-analytics.cs.colorado.edu','27018')
  DB = mongo_conn[options.db]
  COLL = DB['changesets']

  query = COLL.distinct("uid").first(options.limit)
  uids = query.collect{|x| x.to_i}

  size = uids.count()

  puts "Processing #{size} Users"

  #write_user_bounding_envelopes(options.filename, uids, options.db)
  #write_user_changesets(options.filename, uids, options.db)
  write_changeset_kml(options.filename, uids, options.db, title=options.title)


end
