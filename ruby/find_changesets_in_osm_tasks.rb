'''The largest concern with this approach is that we do not know if the
coordinate systems are perfect'''


require 'json'
require 'epic-geo'
require 'mongo'
require 'time'
require 'geo_ruby/geojson'
require 'rgeo/geo_json'
require 'rgeo/geo_json'
require 'rgeo'
require 'csv'
require 'json'


def load_job_geomtries_from_csv(csv)
  puts "Loading CSV"
  jobs = CSV.read(csv)

  #Read in the Jobs & Use RGeo Appropriately
  puts "Reading Jobs"

  job_geometries = []
  header = jobs.shift
  jobs[1..jobs.size].each do |job|
    this_geometry = GEO_FACTORY.parse_wkt(job[3])
    job_geometries << {:id=>job[0], :title=>job[1], :geometry=>this_geometry, :changesets=>[]}
  end
  return job_geometries
end

def hit_mongo
  '''Hit Mongo to get the changesets'''

  puts "Hitting Mongo"
  res = COLL.find(  selector = {'created_at'=>
                                    {'$gt'=>Time.new(2013,11,8),
                                    '$lt'=>Time.new(2013,12,8)}},
                    options =  {:limit=>10000,
                                :fields=>['geometry','user','id','created_at','closed_at']})
  puts "Found #{res.count} results"
  return res
end





#Main Runtime
if $0 == __FILE__
  CONN = Mongo::MongoClient.new('localhost',27017)
  DB = CONN['philippines']
  COLL = DB['changesets']
  #This is the only factory that will properly read the data from OSM Task Manager
  GEO_FACTORY = RGeo::Geos.factory
  #This is the default factory for converting lat/long to something that works (Probably mercator)
  GEO_PROJECTED_FACTORY = RGeo::Geographic.projected_factory(:projection_proj4=>'+proj=merc +lon_0=0 +k=1 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs <>')


  job_geometries = load_job_geomtries_from_csv('/Users/jenningsanderson/Google Drive/OSM-Haiti-Philippines-SocialComputing/data/jobs_output2.csv')

  res = hit_mongo

  '''Go through the changeset geometries'''
  res.each_with_index do |changeset, index|
    set_geom = RGeo::GeoJSON.decode(changeset['geometry'].to_json, {:geo_factory=>GEO_PROJECTED_FACTORY, :json_parser=>:json})

    job_geometries.each do |job|
      if set_geom.projection.within? job[:geometry]
        job[:changesets] << job[:id]
      end
    end

    if (index%1000).zero?
      puts "Processed #{index} changesets thus far"
    end
  end

  job_geometries.each do |job|
    puts "#{job[:title]} -> #{job[:changesets].count}"
  end


end#end of main runtime
