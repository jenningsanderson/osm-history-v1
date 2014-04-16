//Remove changesets with totally invalid geometries ... where did these even come from?
var cnt = 0
db.changesets.find().forEach(function(doc){
	if (doc.geometry!=undefined){
		coords = doc.geometry.coordinates[0]
		coords.forEach(function(elem){
			lon = Math.abs(elem[0])
			lat = Math.abs(elem[1])
			if (lon > 180){
				delete doc.geometry
				db.changesets.update({id : doc.id}, doc)
				cnt++
			}
			else if (lat > 90){
				delete doc.geometry
				db.changesets.update({id : doc.id}, doc)
			}
		})
	}
})

//Update the changesets to change malformed polygons to points
var cnt = 0
db.changesets.find().forEach(function(doc){
	if (doc.geometry !=undefined){
		if (doc.geometry.type != "Point"){
			max_lat = parseFloat(doc.max_lat)
			min_lat = parseFloat(doc.min_lat)
			max_lon = parseFloat(doc.max_lon)
			min_lon = parseFloat(doc.min_lon)
			if (Math.abs(max_lat - min_lat) <= .0000001){
				doc.geometry.type = "Point"
				doc.geometry.coordinates = [max_lon, max_lat]
				db.changesets.update({id : doc.id}, doc)
				cnt++
			}
			else if (Math.abs(max_lon - min_lon) <= .0000001){
				doc.geometry.type = "Point"
				doc.geometry.coordinates = [max_lon, max_lat]
				db.changesets.update({id : doc.id}, doc)
				cnt++
			}
		}
	}
})