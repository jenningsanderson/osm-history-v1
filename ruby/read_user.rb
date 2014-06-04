require 'json'
require 'pp'
require 'net/http'
require 'mongo'
require 'net/http'
require 'uri'
require 'nokogiri'
require 'time'
require 'optparse'

URI_USERS = "http://api.openstreetmap.org/api/0.6/user/"
USERS = [5974, 147211, 29632, 55724, 33103, 36080, 226760, 109294, 18141, 202774, 30854, 6389, 5735, 18069, 223439, 57645, 73889, 13363, 4671, 27099, 51722, 55777, 81244, 119313, 2164, 109362, 28748, 85314, 77446, 69628, 61217, 57054, 1295, 69966, 17306, 2407, 1267, 63969, 122607, 28775, 66160, 49111, 38648, 150272, 117927, 219591, 201359, 143, 3114, 42938, 222391, 60234, 42537, 33217, 43766, 85853, 59758, 4559, 83544, 33705, 47355, 12178, 29055, 50118, 77114, 58339, 23030, 70359, 10549, 45481, 24965, 31118, 6669]

USERS.each do |user|
	h = hit_api(user) 
	pp h
end


def parse_response(response)
	a = {}
	response.children.each do |node|
		unless node.attributes.empty?
			node.children.each do |obj|
				obj.attributes.each do |k,v|
					a[v.name] = v.value
				end
			end
		end
	end
	return a
end

def hit_api(user_id)
	begin
		uri = URI.parse(URI_USERS + user_id)
		response = Net::HTTP.get(uri)
		user_xml = Nokogiri::XML.fragment(response)
		user_h = parse_response(user_xml)
		return user_h
	rescue
		puts "Unsuccessful for user: #{user_id}"
		puts $!
		return false
	end
end
