require 'JSON'
require 'pp'
require 'net/http'

#Haiti URI (within the bounding box)
#This specifies the bounding box coordinates AND the limit of notes we want back. As of [4/11/2014], TOTAL: 632 Notes
uri = URI("http://api.openstreetmap.org/api/0.6/notes.json?limit=1000&bbox=-74.5532226563,17.8794313865,-71.7297363281,19.9888363024")
haiti_payload = Net::HTTP.get(uri)
haiti_notes_collection = JSON.load(haiti_payload)
notes = haiti_notes_collection["features"]

#Sample output
p "[INFO]: Collected #{notes.size} Notes from the Haiti Bounding Box Set."
p "[INFO]: Sample Output:"
pp notes[0]
