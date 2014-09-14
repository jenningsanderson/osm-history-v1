MapReduce Functions
===================
Here are some javascript functions that can be run from the Mongo js shell to perform calculations on the data.

## Total number of nodes created or edited per hour

	var map = function () {
	  var key = this.date.getFullYear() + "-" + this.date.getMonth() + "-" + this.date.getDate() + "-" + this.date.getHours()
	  emit(key, 1)
	}
	
	var reduce = function(key, values){
	  for(var i=0, sum=0; i < values.length; i++){
	    sum += values[i];
	  }
	  return sum;
	}
	
	db.nodes.mapReduce(map, reduce, { out: 'users_hours' });


## Total number of nodes created or edited per day

	var map = function () {
	  var key = this.date.getFullYear() + "-" + this.date.getMonth() + "-" + this.date.getDate()
	  emit(key, 1)
	}
	
	var reduce = function(key, values){
	  for(var i=0, sum=0; i < values.length; i++){
	    sum += values[i];
	  }
	  return sum;
	}
	
	db.nodes.mapReduce(map, reduce, { out: 'users_days' });

## Total number of nodes created or edited per month

	var map = function () {
	  var key = this.date.getFullYear() + "-" + this.date.getMonth()
	  emit(key, 1)
	}
	
	var reduce = function(key, values){
	  for(var i=0, sum=0; i < values.length; i++){
	    sum += values[i];
	  }
	  return sum;
	}
	
	db.nodes.mapReduce(map, reduce, { out: 'months_nodes' });

## Changesets by month with number of nodes edited in each

	var map = function () {
	  emit({changeset: this.properties.changeset ,date: this.date.getFullYear() + "-" + this.date.getMonth()}, { count: 1 });
	}
	
	var reduce = function(key, values) {
	  var count = 0;
	
	  values.forEach(function(v) {
	    count += v['count'];
	  });
	
	  return {count: count};
	}
	
	db.nodes.mapReduce(map, reduce, { out: 'changesets_month' });
	db.changesets_month.find({})
	

## Users by month step 1

	var map = function () {
	  emit({ date: this.date.getFullYear() + "-" + this.date.getMonth(), user: this.properties.uid },{ count: 1 });
	}
	
	var reduce = function(key, values) {
	  var count = 0;
	  values.forEach(function(v) {
	    count += v.count;
	  });
	
	  return {
	    count: count
	    };
	}
	
	db.nodes.mapReduce(map, reduce, { out: 'users_months_step1' });

## Users by month step 2

	db.users_months_step1.group(
	   {
	     key: { "_id.date" },
	     reduce: function( curr, result ) {
	            result.total += 1;
	             },
	     initial: { total:0 }
	   }
	)


## Lat/Lon
	var map = function () {
	  var year = this.date.getFullYear();
	  var month = this.date.getFullYear() + "-" + this.date.getMonth();
	  var day = this.date.getFullYear() + "-" + this.date.getMonth() + "-" + this.date.getDate();
	  emit(this._id, { "day": day, "month": month, "year": year, "lat": this.properties.lat, "lon": this.properties.lon	} );
	}
	
	var reduce = function(key, values){
	  return values;
	}
	db.nodes.mapReduce(map, reduce, { out: 'location_nodes', sort: { "date":1 }, query: { "properties.lat": {$ne: 0}, "date" : { $gte : new ISODate("2012-11-11T20:15:31Z") } } });

## FLATTEN RESULTS INTO NEW TABLE
	db.location_nodes.find({}).forEach( function(result) {
		db.location.insert({_id: result._id, day: result.value.day, month: result.value.month, year: result.value.year, lat: result.value.lat, lon: result.value.lon })
	});

## Export to CSV Example
	mongoexport -d kathmandu -c location -f '_id,year,month,day,lat,lon' --csv -o ~/Dropbox/Grad\ School/Spring\ 2014/Quantitative\ Methods/Assignments/Final\ Project/Data/locations.csv
