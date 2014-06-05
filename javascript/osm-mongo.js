
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



function haiti_get_total_changesets(users){
     var total = 0
     print("going to work on " + users.length + " users")
     for (var i = 0; i < users.length; i++){
          print("Working on user #" + i + " "  + users[i])
          total += db.changesets.find({"user":users[i], "closed_at": {"$gte": ISODate("2010-01-12"), "$lte": ISODate("2010-02-12")}}).count()
     }
     return total
}



function philippines_get_total_nodes_edited(users){
     var total = 0
     print("going to work on " + users.length + " users")
     for (var i = 0; i < users.length; i++){
          print("Working on user #" + i + " "  + users[i])
          total += db.nodes.find({"properties.user":users[i], "date": {"$gte": ISODate("2013-11-08"), "$lte": ISODate("2013-12-08")}}).count()
     }
     return total
}



function philippines_get_total_changesets(users){
     var total = 0
     print("going to work on " + users.length + " users")
     for (var i = 0; i < users.length; i++){
          print("Working on user #" + i + " "  + users[i])
          total += db.changesets.find({"user":users[i], "closed_at": {"$gte": ISODate("2013-11-08"), "$lte": ISODate("2013-12-08")}}).count()
     }
     return total
}