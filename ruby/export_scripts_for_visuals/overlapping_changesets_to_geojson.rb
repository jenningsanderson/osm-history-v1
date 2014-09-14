require 'json'
require 'epic-geo'
require 'mongo'
require 'time'
require 'geo_ruby/geojson'

class GetChangesetGeometries
  attr_reader :changeset, :geometries, :bbox, :time_open, :time_close, :user
  def initialize(changeset, database=FALSE)
    @changeset = changeset
    @geometries = []
    if database
      @database = database
    else
      @database = DB
    end
  end

  def get_changeset_nodes
    query = @database['nodes'].find({'properties.changeset'=>@changeset}, 
    								{:fields => ['geometry', 'date', 'properties.user']})
	query.each do |node_geometry|
    	@geometries << GeoRuby::SimpleFeatures::Geometry.from_geojson(node_geometry['geometry'].to_json)
    end
    
    bbox_geom = GeoRuby::SimpleFeatures::GeometryCollection.from_geometries(@geometries)
    envelope = bbox_geom.envelope
    attrs = @database['changesets'].find({'id'=>@changeset},{:fields=>['created_at','closed_at','user']}).first
    @time_open = attrs['created_at']
    @time_close = attrs['closed_at']
    @user = attrs['user']
    
    @bbox =GeoRuby::SimpleFeatures::Polygon.from_coordinates(
          [[[envelope.lower_corner.x, envelope.lower_corner.y],
            [envelope.lower_corner.x, envelope.upper_corner.y],
            [envelope.upper_corner.x, envelope.upper_corner.y],
            [envelope.upper_corner.x, envelope.lower_corner.y],
            [envelope.lower_corner.x, envelope.lower_corner.y]]] )
    end
end


event = ARGV[0]
event ||= 'haiti'

mongo_conn = Mongo::MongoClient.new("epic-analytics.cs.colorado.edu", 27018)
DB = mongo_conn[event]

conflict_nodes = JSON.parse(File.open("#{event}_conflict_nodes_diff_users.json",'r').read)

outfile = GeoJSONWriter.new("#{event}_overlapping_nodes.geojson")
outfile.write_header

conflict_nodes.keys.each do |node|

	puts "#{node}-->#{conflict_nodes[node]}"
	
	conflict_nodes[node].each do |changeset_pair|
		
		#Get geometry of conflict
		first = GetChangesetGeometries.new(changeset_pair[0])
		first.get_changeset_nodes
		conflict = GetChangesetGeometries.new(changeset_pair[1])
		conflict.get_changeset_nodes
		
		
		this_first = {:geometry=>first.bbox}
		this_first[:properties] = {
      		:name => "first-#{first.changeset}",
          	:open => first.time_open.strftime("%Y-%m-%d %H:%M:%S"),
          	:close=> first.time_close.strftime("%Y-%m-%d %H:%M:%S"),
            :style =>"first",
            :desc => %Q{Node:   #{node}
            			Time Open:   #{first.time_open}
            			Time close:  #{first.time_close}
             			User:   #{first.user} }
        }

        this_conflict = {:geometry=>conflict.bbox}
		this_conflict[:properties] = {
      		:name => "conflict-#{first.changeset}",
          	:open => conflict.time_open.strftime("%Y-%m-%d %H:%M:%S"),
          	:close=> conflict.time_close.strftime("%Y-%m-%d %H:%M:%S"),
            :style =>"conflict",
            :desc => %Q{Node:   #{node}
            			Time Open:   #{first.time_open}
            			Time close:  #{first.time_close}
             			User:   #{first.user} }
        }

        outfile.write_feature(this_first[:geometry], this_first[:properties])
        outfile.write_feature(this_conflict[:geometry], this_conflict[:properties])
	end
end

outfile.write_footer