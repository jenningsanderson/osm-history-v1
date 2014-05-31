'''The largest concern with this approach is that we do not know if the
coordinate systems are perfect'''

require 'json'
require 'epic-geo'
require 'mongo'
require 'time'
require 'geo_ruby/geojson'
require 'rgeo/geo_json'
require 'rgeo'
require 'csv'
require 'json'

'''Read in the Jobs & Use RGeo Appropriately'''
def load_job_geomtries_from_csv(csv)
  puts "Reading Jobs from CSV"
  jobs = CSV.read(csv)
  job_geometries = []
  header = jobs.shift
  jobs[1..jobs.size].each do |job|
    unless job[0]=="341"
      this_geometry = GEO_FACTORY.parse_wkt(job[3])
      job_geometries << {:id=>job[0], :title=>job[1],
                       :geometry=>this_geometry,
                       :changesets=>[]}
    end
  end
  return job_geometries
end

'''Load and parse the tiles history export from the OSM TM DB'''
def load_tiles_history_from_csv(csv)
  puts "Parsing tiles_history"
  tiles = CSV.read(csv)
  tiles_history = {}
  tiles[1..-1].each do |tile|
    tiles_history[tile[0]] ||= []
    tiles_history[tile[0]] << {:user=>tile[1], :date=>tile[2], :comment=>tile[3]}
  end
  return tiles_history
end

'''Hit Mongo to get the changesets'''
def hit_mongo
  puts "Hitting Mongo"
  res = COLL.find(  selector = {'created_at'=>
                                    {'$gt'=>Time.new(2013,11,8),
                                    '$lt'=>Time.new(2013,12,8)},
                                'area'=>{'$lt'=>100000000}},
                    options =  {:limit=>nil,
                                :fields=>['geometry','user','id','created_at','closed_at']})
  puts "Found #{res.count} results"
  return res
end

def write_geojson_jobs(job_geometries)
  jobs_geojson = GeoJSONWriter.new('jobs_geometries')
  jobs_geojson.add_options([:crs=>{:type=>:name,
                                   :properties=>{:name=>"EPSG:900913"}}])
  jobs_geojson.write_header
  job_geometries.each do |job|
  #  puts job[:geometry].srid
    jobs_geojson.write_feature(RGeo::GeoJSON.encode(job[:geometry]), {:job_id=>job[:id],:title=>job[:title]})
  end
  jobs_geojson.write_footer
end


#Main Runtime
if $0 == __FILE__
  CONN = Mongo::MongoClient.new('epic-analytics.cs.colorado.edu',27018)
  DB = CONN['philippines']
  COLL = DB['changesets']
  #This is the only factory that will properly read the data from OSM Task Manager
  GEO_FACTORY = RGeo::Geos.factory
  #This is the default factory for converting lat/long to something that works (Probably mercator)
  GEO_PROJECTED_FACTORY = RGeo::Geographic.projected_factory(:projection_proj4=>'+proj=merc +lon_0=0 +k=1 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs <>')

  job_geometries = load_job_geomtries_from_csv('/Users/jenningsanderson/Google Drive/OSM-Haiti-Philippines-SocialComputing/data/jobs_output5.csv')

  jobs_tiles_history = load_tiles_history_from_csv('/Users/jenningsanderson/Google Drive/OSM-Haiti-Philippines-SocialComputing/data/tiles_history3.csv')

  #Write a job_geometries geojson file (Only need to do this once...)
  #write_geojson_jobs(job_geometries)

  res = hit_mongo

  number_changesets = res.count

  '''Write a changesets geojson file'''
  # changesets_geojson = GeoJSONWriter.new('changeset_geometries_area_limited_intersects')
  # changesets_geojson.add_options([:crs=>{:type=>:name,
  #                                 :properties=>{:name=>"EPSG:900913"}}])
  # changesets_geojson.write_header

  missing_jobs = [] #This is an array of changeset IDs that do not correspond with any TM Job

  #Get list of distinct users for OSM and for TM
  tm_distinct_users = jobs_tiles_history.map{|id, tiles| tiles.map{|tile| tile[:user]}}.flatten.uniq
  distinct_osm_users = []

  recognized_user_edit_in_bound = []
  recognized_user_edit_out_bound = []
  unrecognized_user_edit_in_bound = []
  unrecognized_user_edit_out_bound = []

  '''Go through the changeset geometries'''
  res.each_with_index do |changeset, index|
    set_geom = RGeo::GeoJSON.decode(changeset['geometry'].to_json, {:geo_factory=>GEO_PROJECTED_FACTORY, :json_parser=>:json})

    this_user = changeset['user']

    unless distinct_osm_users.include? this_user
      distinct_osm_users << this_user
    end

    #Set a flag: This changeset does not yet have a job associated with it
    has_job = false
    job_geometries.each do |job|

      #Check if the edit occured inside of a valid TM Job.
      if set_geom.projection.intersects? job[:geometry]
        job[:changesets] << changeset['id']

        '''Write the changeset to geojson?'''
        # changesets_geojson.write_feature(RGeo::GeoJSON.encode(set_geom.projection),
          # {:inside=>job[:id], :created_at=>changeset['created_at'].strftime("%Y-%m-%d %H:%M:%S")})

        #Call off the flag, if the flag is false
        unless has_job
          has_job=true
        end

      #Else the Edit occured outside of a TM Job
      end
    end

    #So we know that this changeset could have belonged to at least one job, good enough.
    if has_job
      if tm_distinct_users.include? this_user
        recognized_user_edit_in_bound << this_user
      else
        unrecognized_user_edit_in_bound << this_user
      end
    else
      #Add the changeset to the changesets missing tasks array
      missing_jobs << changeset[:id]

      if tm_distinct_users.include? this_user
        recognized_user_edit_out_bound << this_user
      else
        unrecognized_user_edit_out_bound << this_user
      end

      '''Tell the geojson file about it'''
      # changesets_geojson.write_feature(RGeo::GeoJSON.encode(set_geom.projection), {:inside=>999, :created_at=>changeset['created_at'].strftime("%Y-%m-%d %H:%M:%S")})
    end

    if (index%1000).zero?
      puts "Processed #{index} changesets thus far"
    end
  end

  '''Close the GeoJSON file'''
  #changesets_geojson.write_footer

  job_geometries.each do |job|
    puts "#{job[:id]}: Contains #{job[:changesets].count} changesets "
  end

  #The changeset percentage stats
  puts "\nChangesets with no associated Tasking Manager Job by Geography: #{missing_jobs.count}"
  puts "This means #{(missing_jobs.count.to_f/number_changesets*100).round(2)}% of the changesets in the disaster window were MOST LIKELY not made with the help of the Tasking Manager"

  #Some User Stats
  puts "\nDistinct Users found from Tasking Manager DB: #{tm_distinct_users.count}"
  puts "Distinct Users found from OSM: #{distinct_osm_users.count}"

  puts "The TM distinct user count seems way, way, too high, I don't like this number."

  user_union = distinct_osm_users & tm_distinct_users
  puts "\nUnion: #{user_union.count}, implies that #{user_union.count} users actively used the tasking manager to make changes to OSM during the disaster window"

  puts "\nOf #{number_changesets} total changesets:"

  rec_in_bounds_edits   = recognized_user_edit_in_bound.count
  rec_out_bounds_edits  = recognized_user_edit_out_bound.count
  unrec_in_bound_edits  = unrecognized_user_edit_in_bound.count
  unrec_out_bound_edits = unrecognized_user_edit_out_bound.count

  puts "% of edits made by recognized users inside of valid tasks: #{(rec_in_bounds_edits.to_f/number_changesets*100).round(2)}%"
  puts "% of edits made by recognized users outside of valid tasks: #{(rec_out_bounds_edits.to_f/number_changesets*100).round(2)}%"
  puts "% of edits made by unrecognized users inside of valid tasks: #{(unrec_in_bound_edits.to_f/number_changesets*100).round(2)}%"
  puts "% of edits made by unrecognized users outside of valid tasks: #{(unrec_out_bound_edits.to_f/number_changesets*100).round(2)}%"

  recognized_user_edit_in_bound.uniq!
  recognized_user_edit_out_bound.uniq!
  unrecognized_user_edit_in_bound.uniq!
  unrecognized_user_edit_out_bound.uniq!

  #Now find users that mapped in Haiti and the Philippines that also show up in the Task manager list
  intersect_users = [  "jgc",  "bielebog",  "Grausewitz",  "kjon","chippy","eknus","MAPconcierge","PierZen","Steven Citron-Pousty","andygates","maning","ajeba","katpatuka","Lübeck","jaakkoh","Harry Wood","rjhale1971","higa4","marcschneider","ikiya","fil","florisje","alv","malenki","robert","EdLoach","Dave Smith","mapistanbul","Jesús Gómez","clara","wonderchook","niubii","simone","StellanL","MickO","ecaldwell","theonlytruth","Martin_Jensen","Andy Stricker","Samusz","brunosan","geografa","CaptainCrunch","vsandre","keinseier","mabapla","sev_hotosm","sejohnson","SK53","25or6to4","Paul The Archivist","AlNo","springmeyer","bahnpirat"]

  puts "The Intersect of intersect users and distinct tm users is: #{(tm_distinct_users & intersect_users).count} users."

end
