require 'rgeo'

#Figure out what the fuck is wrong with these projections

factory_we_used = RGeo::Geographic.projected_factory(:projection_proj4=>'+proj=merc +lon_0=0 +k=1 +x_0=0 +y_0=0 +ellps=WGS84 +datum=WGS84 +units=m +no_defs <>')

simple_m_f      = RGeo::Geographic.simple_mercator_factory

spherical_fact  = RGeo::Geographic.spherical_factory # <= Each of these takes 

web_mercator    = RGeo::Geographic.projected_factory(:srid=>3857, :projection_proj4=>"+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +wktext  +no_defs")

straight_up     = RGeo::Geographic.projected_factory(:projection_proj4=>"+proj=longlat +datum=WGS84 +no_defs ")

equidistant     = RGeo::Geographic.projected_factory(:projection_proj4=>"+proj=eqdc +lat_0=39 +lon_0=-96 +lat_1=33 +lat_2=45 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs ")

preferred       = RGeo::Geos.factory_generator(:srid=>4326)


#So the point we want is this:
lat1 = 40.00828898487092  		#Folsom Hill
lon1 = -105.264151096344

lat2 = 40.014599938522146 		#Bottom of Folsom Hill
lon2 = -105.26302456855774

# lon1 = -108.28125
# lat1 = 42.81152174509788

# lon2 = -73.95996093749999
# lat2 = 40.713955826286046

#Testing the factory we used: 

p1_us = factory_we_used.point(lon1,lat1)
p2_us = factory_we_used.point(lon2,lat2)

p1_mf = simple_m_f.point(lon1,lat1)
p2_mf = simple_m_f.point(lon2,lat2)

p1_sp = spherical_fact.point(lon1,lat1)
p2_sp = spherical_fact.point(lon2,lat2)

p1_wm = web_mercator.point(lon1,lat1)
p2_wm = web_mercator.point(lon2,lat2)

p1_su = straight_up.point(lon1,lat1)
p2_su = straight_up.point(lon2,lat2)

p1_eq = equidistant.point(lon1,lat1)
p2_eq = equidistant.point(lon2,lat2)

puts "The factory we used gives point: #{p1_us.as_text} with distance: #{p1_us.distance(p2_us)}"
puts "The simple mercator factory gives: #{p1_mf.as_text} with distance: #{p1_mf.distance(p2_mf)}"
puts "The Spherical factory gives: #{p1_sp.as_text} with distance: #{p1_sp.distance(p2_sp)}"
puts "The Web Mercator factory gives: #{p1_wm.as_text} with distance: #{p1_wm.distance(p2_wm)}"
puts "The Straight up 4326 factory gives: #{p1_su.as_text} with distance: #{p1_su.distance(p2_su)}"
puts "The Equidistant factory for USA gives: #{p1_eq.as_text} with distance: #{p1_eq.distance(p2_eq)}"


#Testing the simple_m_f factory: