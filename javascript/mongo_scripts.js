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

//Fix an error to reform the points...
var cnt = 0
db.changesets.find({"geometry.coordinates" : [ [ [ 0.0, 0.0 ], [ 0.0, 0.0 ], [ 0.0, 0.0 ], [ 0.0, 0.0 ], [ 0.0, 0.0 ] ] ]}).forEach(function(doc){
	delete doc.geometry
	db.changesets.update({id : doc.id}, doc)
})


//Add joining date to the users changeset
var missing = 0
var size = db.changesets.count()
var cnt = 0
db.changesets.find().forEach(function(changeset){
	var doc = db.users.findOne({uid : changeset.uid.toString()})
	if (doc!= undefined){
		var join = doc.joiningdate
		db.changesets.update({id : changeset.id}, {$set : {userjoin : join}})
		changeset.save
	}
	else{
		missing++
	}
	cnt++
	if(cnt%100==0){
		print("Left: "+(size-cnt).toString())
	}
});
