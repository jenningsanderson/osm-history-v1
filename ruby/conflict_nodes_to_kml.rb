require 'json'
require 'epic-geo'
require 'mongo'
require 'time'
require 'geo_ruby/geojson'

event = ARGV[0]
event ||= 'haiti'

mongo_conn = Mongo::MongoClient.new("epic-analytics.cs.colorado.edu", 27018)
DB = mongo_conn[event]

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

conflict_nodes = JSON.parse(File.open("#{event}_conflict_nodes_diff_users.json",'r').read)

kml_output = KMLAuthor.new("#{event}_diff_users_overlapping_changesets", )
kml_output.write_header("Conflicting Changesets by Node")
add_style(kml_output.openfile, {:id=>"first", :polygon=>{:color=>"#7700FF00"}, :point=>{:color=>"#7700FF00", :size=>0}})
add_style(kml_output.openfile, {:id=>"conflict", :polygon=>{:color=>"#77FF00FF"}, :point=>{:color=>"#77FF00FF", :text=>0}})

conflict_nodes.keys.each do |node|

	puts "#{node}-->#{conflict_nodes[node]}"
	
	this_node_folder = {:name=>node, :folders=>[]}

	conflict_nodes[node].each do |changeset_pair|
		
		#Get geometry of conflict
		first = GetChangesetGeometries.new(changeset_pair[0])
		first.get_changeset_nodes
		conflict = GetChangesetGeometries.new(changeset_pair[1])
		conflict.get_changeset_nodes
		
		this_conflict = {:name=>"conflict", :features=>[]}
			
		this_conflict[:features] <<{
      		:name => "first-#{first.changeset}",
          	:geometry => first.bbox,
            :time => first.time_open,
            :style =>"#first",
            :desc => %Q{Node:   #{node}
            			Time Open:   #{first.time_open}
            			Time close:  #{first.time_close}
             			User:   #{first.user} }
        }
        this_conflict[:features] <<{
        	:name => "conflict-#{conflict.changeset}",
          	:geometry => conflict.bbox,
            :time => conflict.time_open,
            :style => "#conflict",
            :desc => %Q{Node:   #{node}
            			Time Open:   #{conflict.time_open}
            			Time Close:  #{conflict.time_close}
             			User:   #{conflict.user} }
        }
		
		unless conflict.user == first.user
			this_node_folder[:folders ] << this_conflict
		end
	end
	unless this_node_folder[:folders].empty?
		kml_output.write_folder this_node_folder
	end
end

kml_output.write_footer