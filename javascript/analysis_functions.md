Various Javascript Functions for analysis
==========================================

##Get total nodes edited for a list of users (currently set for Philippines)

	function get_total_nodes_edited(users){
	     var total_edits = 0;
	     var user_count = 0;
	     missing_users = []
	     print("going to work on " + users.length + " users")
	     for (var i = 0; i < users.length; i++){
	          print("Working on user #" + i + " "  + users[i])
	          edit_count = db.nodes.find({"properties.user":users[i], "date": {"$gte": ISODate("2013-11-08"), "$lte": ISODate("2013-12-08")}}).count()
	          if (edit_count != 0){
	               total_edits+=edit_count;
	               user_count +=1;
	          }
	          else{
	          }
	     }
	     print("Number of Users: "+user_count)
	     print("Number of Edits: "+total_edits)
	}

##Get total changesets for a list of users in Haiti during the disaster window

	function haiti_get_total_changesets(users){
	     var total = 0
	     print("going to work on " + users.length + " users")
	     for (var i = 0; i < users.length; i++){
	          print("Working on user #" + i + " "  + users[i])
	          total += db.changesets.find({"user":users[i], "closed_at": {"$gte": ISODate("2010-01-12"), "$lte": ISODate("2010-02-12")}}).count()
	     }
	     return total
	}

##Get total changesets for a list of users in Philippines during the disaster window

	function philippines_get_total_changesets(users){
	     var total = 0
	     print("going to work on " + users.length + " users")
	     for (var i = 0; i < users.length; i++){
	          print("Working on user #" + i + " "  + users[i])
	          total += db.changesets.find({"user":users[i], "closed_at": {"$gte": ISODate("2013-11-08"), "$lte": ISODate("2013-12-08")}}).count()
	     }
	     return total
	}

##Get total nodes edited in just the Philippines disaster window
	function philippines_get_total_nodes_edited(users){
	     var total = 0
	     print("going to work on " + users.length + " users")
	     for (var i = 0; i < users.length; i++){
	          print("Working on user #" + i + " "  + users[i])
	          total += db.nodes.find({"properties.user":users[i], "date": {"$gte": ISODate("2013-11-08"), "$lte": ISODate("2013-12-08")}}).count()
	     }
	     return total
	}



	/*
	This first script counts the unique users that were in both datasets.

	The filter function came from some internet wizardy here:
	http://stackoverflow.com/questions/1885557/simplest-code-for-array-intersection-in-javascript
	*/
	var haiti_start = new Date(2010,0,12);
	var haiti_end   = new Date(2010,1,12);

	var phil_start  = new Date(2013,10,8);
	var phil_end    = new Date(2013,11,8);

	use haiti
	haiti_users = db.nodes.distinct('properties.user',{date : {$gt : haiti_start, $lt : haiti_end}});

	use philippines
	phil_users  = db.nodes.distinct('properties.user',{date : {$gt : phil_start, $lt : phil_end}});

	intersect = phil_users.filter(function(n){return haiti_users.indexOf(n)!=-1});

	/*
	The intersection is:
	[
		17497,
		37392,
		82783,
		27741,
		24748,
		1987,
		28775,
		1417,
		2407,
		55462,
		24440,
		77109,
		226516,
		7230,
		69966,
		44217,
		1611,
		87991,
		29639,
		175523,
		39504,
		1295,
		4660,
		171863,
		219187,
		129535,
		85314,
		13363,
		167616,
		27099,
		139043,
		25398,
		5045,
		3114,
		128907,
		84681,
		109362,
		44200,
		137,
		6389,
		13203,
		37542,
		67931,
		113972,
		162590,
		55777,
		3209,
		57884,
		69628,
		95488,
		219668,
		86027,
		104461,
		26838
	]
	*/

	var arrayUnique = function(a) {
	    return a.reduce(function(p, c) {
	        if (p.indexOf(c) < 0) p.push(c);
	        return p;
	    }, []);
	};


	//Set Variables
	var haiti_start = new Date(2010,0,12);
	var haiti_end   = new Date(2010,1,12);
	var phil_start  = new Date(2013,10,8);
	var phil_end    = new Date(2013,11,8);
	use philippines;

	var potential_buildings = db.changesets.distinct('id',{created_at : {$gt : phil_start, $lt : phil_end},node_count : 4})

	building_count = 0;
	potential_buildings.forEach(function(changeset){
		doc = db.ways.findOne({'properties.changeset' : changeset})
		if (doc!=undefined){
			if (doc.properties.tags!=undefined){
				if (doc.properties.tags.building != undefined){
					building_count++
				}
			}
		}
	})







