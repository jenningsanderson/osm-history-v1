'''
May 2014
This script hits the EPIC Mongo OSM database and visualizes changesets by node.
'''
require 'mongo'
require 'optparse'
require 'ostruct'
require 'rgeo'
require 'rgeo/geo_json'
require 'geo_ruby/geojson'
require 'csv'
require 'epic-geo' #Custom gem for epic


class GetNodeGeometries

  @@factory = RGeo::Geographic.projected_factory(:projection_proj4 =>'+proj=merc +lon_0=0 +k=1 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs')

  attr_reader :set_geometries, :name, :changeset_bboxes

  def initialize(user, database=FALSE)
    @uid = user[:id]
    @sets = user[:changesets]
    @set_geometries = {}
    @changeset_bboxes = []
    if database
      @database = database
    else
      @database = DB
    end
  end

  def convert_to_rgeo(georuby_polygon)
    RGeo::GeoJSON.decode(georuby_polygon.to_json, {:geo_factory=>@@factory, :json_parser=>:json})
  end

  def hit_nodes_collection
    @sets.each do |set|
      query = @database['nodes'].find(selector = {'properties.changeset'=>set}, opts = {:fields => ['geometry', 'date', 'properties.user']})
      count = query.count
      if (count < 10000) #Only get those that we can really use
        @name = query.each.first['properties']['user']
        query.rewind! #Put it back to beginning...

        @set_geometries[set] ||= []

        query.each do |node_geometry|
          @set_geometries[set] << {
            :geometry=>GeoRuby::SimpleFeatures::Geometry.from_geojson(node_geometry['geometry'].to_json),
            :properties=>{:date=>node_geometry['date'], :user=>node_geometry['properties']['user']}}
        end
        this_bbox = GeoRuby::SimpleFeatures::GeometryCollection.from_geometries(@set_geometries[set].collect{|obj| obj[:geometry]})
        envelope = this_bbox.envelope
        time = @database['changesets'].find({'id'=>set},{:fields=>['created_at']}).first
        bbox =GeoRuby::SimpleFeatures::Polygon.from_coordinates(
          [[[envelope.lower_corner.x, envelope.lower_corner.y],
            [envelope.lower_corner.x, envelope.upper_corner.y],
            [envelope.upper_corner.x, envelope.upper_corner.y],
            [envelope.upper_corner.x, envelope.lower_corner.y],
            [envelope.lower_corner.x, envelope.lower_corner.y]]] )
        area = convert_to_rgeo(bbox).area/1000000
        if area.zero?
          bbox = GeoRuby::SimpleFeatures::Point.from_coordinates([envelope.lower_corner.x, envelope.lower_corner.y])
        end
        count = @set_geometries[set].size
        density = count / area
        if density == Float::INFINITY
          density = 1
        end
        @changeset_bboxes << {:time => time['created_at'], :bbox => bbox, :area => area.round(2), :count=>count, :density =>density.round(2)}
      end #End the unless
    end
  end
end

####################################################
############   Implicit Runtime    #################
####################################################

if __FILE__ == $0
  options = OpenStruct.new
  opts = OptionParser.new do |opts|
    opts.banner = "Usage: ruby get_changesets.rb -d DATABASE  -f FILENAME [-l LIMIT]"
    opts.separator "\nSpecific options:"
    opts.on("-d", "--database Database Name",
            "Name of Database (Haiti, Philippines)"){|v| options.db = v }
    opts.on("-f", "--filename Output Filename",
            "Name of output file"){|v| options.filename = v }
    opts.on("-w", "--what What to write (n,p,b)",
            "What to write to KML: nodes (p), polygons (p), or both (b)"){|v| options.what = v }
    opts.on("-c", "--csv Write csv (t or f)",
            "Write to CSV output"){|v| options.csv = v }
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
  unless options.db and options.filename and options.what
    puts opts
    exit
  end
  options.limit ||= 100000

  mongo_conn = Mongo::MongoClient.new('epic-analytics.cs.colorado.edu','27018')
  #mongo_conn = Mongo::MongoClient.new #Defaults to localhost (For offline use)
  DB = mongo_conn[options.db]
  COLL = DB['changesets']

  TIMES = {:haiti=>{
                    :start=>Time.new(2010,1,12),
                    :end  =>Time.new(2010,2,12)},

                  :philippines=>{
                    :start=>Time.new(2013,11,8),
                    :end  =>Time.new(2013,12,8)}
                 }


  ''' Get a sample of users within some range '''
  query = COLL.distinct("uid",
    {'created_at'=>{'$gt'=>TIMES[options.db.to_sym][:start],
                    '$lt'=>TIMES[options.db.to_sym][:end]}}).sample(options.limit)

  uids = query.collect{|x| x.to_i}
  size = uids.count()
  puts "Processing #{size} Users"

  #Start the KML file
  puts "Opening KML file for writing"
  file = KMLAuthor.new(options.filename)
  file.write_header(options.title)
  #file.generate_random_styles(options.limit)
  file.write_color_ramp_style(20)

  #Start the CSV Output
  puts "Opening the CSV for writing"

  #TODO : MAKE THIS WORK
  max_density = 100

  CSV.open(options.filename+'_data.csv','w') do |csv|
    csv << ['user', 'node_count', 'area', 'density', 'date']

    #Iterate over each of the distinct users.
    uids.each_with_index do |uid, counter|
      begin
        print "Starting User: #{uid}"
        #Get user's changeset
        this_uid = {:id=>uid,
                    :changesets=>COLL.distinct('id',
          {'uid'=>uid, 'created_at'=>{'$gt'=>TIMES[options.db.to_sym][:start],
                                      '$lt'=>TIMES[options.db.to_sym][:end]}})}

        #Process geometries
        this_uid[:geometries] = GetNodeGeometries.new(this_uid)
        this_uid[:geometries].hit_nodes_collection
        this_uid[:name] = this_uid[:geometries].name

        print "...done #{uid}; now writing: #{this_uid[:name]}...(#{(counter*1.0/size*100).round(2)}%)\n"
        this_user = {:name => this_uid[:name], :folders=>[]}

        random = rand(options.limit) #Set a random color for this user

        #Go through each of their changesets, building subfolders
        index = 0
        this_uid[:geometries].set_geometries.each do |k,v|

          #Write to csv
          csv << [ this_uid[:name],
                   this_uid[:geometries].changeset_bboxes[index][:count],
                   this_uid[:geometries].changeset_bboxes[index][:area],
                   this_uid[:geometries].changeset_bboxes[index][:density],
                   this_uid[:geometries].changeset_bboxes[index][:time]
                 ]

          #Make a new folder for this changeset
          changeset_folder = {:name => k, :features=>[]}

          #Each changeset folder gets a geometry feature for the node

          #How dense is it?
          density = this_uid[:geometries].changeset_bboxes[index][:density]
          if density > max_density
            max_density = density
          end

          style = ( (density/max_density) * 20).round #Linear scale

          if options.what == 'p' or options.what == 'b'
            changeset_folder[:features] <<{
              :name => k,
              :geometry => this_uid[:geometries].changeset_bboxes[index][:bbox],
              :time => this_uid[:geometries].changeset_bboxes[index][:time],
              #:style =>"#r_style_#{random}",
              :style =>"#c_ramp_style_#{style}",
              :desc => %Q{Area:    #{this_uid[:geometries].changeset_bboxes[index][:area]}
                          Density: #{this_uid[:geometries].changeset_bboxes[index][:density]}
                          User:    #{this_uid[:name]}}
            }
          end
          if options.what == 'n' or options.what == 'b'
            v.each do |geometry|
              changeset_folder[:features] << {
                :name => k,
                :geometry => geometry[:geometry],
                :time => geometry[:properties][:date],
                :style =>"#r_style_#{random}"
              }
            end
          end

          #Add the changeset folder to the user's folders
          this_user[:folders] << changeset_folder
          index += 1 #Move onto the next changeset
        end
        #Write the user folder
        file.write_folder(this_user)
       rescue
          p $!
          puts caller
          puts "Error occured, moving onto next user"
      end
    end #End user iterator

    puts "Writing footer of KML file"
    file.write_footer
  end #End the csv

end
