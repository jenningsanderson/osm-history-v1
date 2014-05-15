"Scripts for running in shell calculations on the data"


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
haiti_users = db.nodes.distinct('properties.uid',{date : {$gt : haiti_start, $lt : haiti_end}});

use philippines
phil_users  = db.nodes.distinct('properties.uid',{date : {$gt : phil_start, $lt : phil_end}});

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

