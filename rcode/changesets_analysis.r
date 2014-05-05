source("/Users/jenningsanderson/Dropbox/OSM/osm-history/rcode/changeset_functions.r")
library(ggplot2)

#Over-write the timeboxed cursor function
custom_timeboxed_cursor <- function(startDate, endDate, DBNS, q_limit=500000){
  
  # First, define the query
  query = mongo.bson.buffer.create()
  #startDate <- ISOdate(2010,01,12)
  #endDate <- ISOdate(2010,02,12)
  mongo.bson.buffer.start.object(query, "created_at")
  mongo.bson.buffer.append(query, "$gt", startDate)
  mongo.bson.buffer.append(query, "$lt", endDate)
  mongo.bson.buffer.finish.object(query)
  #mongo.bson.buffer.start.object(query, "node_count")
  #mongo.bson.buffer.append(query, "$gt", 1L)
  #mongo.bson.buffer.append(query, "$lt", 10000L)
  #mongo.bson.buffer.finish.object(query)
  query = mongo.bson.from.buffer(query)
  
  # Next, define the fields we want for our dataframe
  fields = mongo.bson.buffer.create()
  mongo.bson.buffer.append(fields, "uid", 1L)
  mongo.bson.buffer.append(fields, "node_count", 1L)
  mongo.bson.buffer.append(fields, "node_density", 1L)
  mongo.bson.buffer.append(fields, "created_at", 1L)
  mongo.bson.buffer.append(fields, "area", 1L)
  mongo.bson.buffer.append(fields, "userjoin", 1L)
  mongo.bson.buffer.append(fields, "_id", 0L)
  fields = mongo.bson.from.buffer(fields)
  
  cursor <- mongo.find(mongo, ns=DBNS, query=query, fields=fields, limit=q_limit, options=mongo.find.exhaust)
  size <<- mongo.count(mongo, ns=DBNS, query)
  if (size == -1){
    size <<- q_limit
  }
  return(cursor)
}

#Philippines
#phil_cursor = custom_timeboxed_cursor(ISOdate(2013,11,08), ISOdate(2013,12,08), 'philippines.changesets')
#phil_info = buildChangeset(phil_cursor)

#Haiti
#haiti_cursor = custom_timeboxed_cursor(ISOdate(2010,01,12), ISOdate(2010,02,12), 'haiti.changesets')
#haiti_info = buildChangeset(haiti_cursor)

#Combine the DFs:
#phil_info$Country  = "Philippines"
#haiti_info$Country = "Haiti"

#dat = rbind(phil_info, haiti_info)

#Investigate density as a function of when the user joined ... missing a lot of data for this -- not good?
#plot(x = phil_info$userjoin, y = phil_info$node_density, main="Philippines: Density vs. when joined")
#plot(x = haiti_info$userjoin, y = haiti_info$node_density, main="Haiti: Density vs. when joined")
#Realize the error with this, it's by changeset, and changesets are inherently random...

#plot(x = phil_info$userjoin, y = phil_info$node_count, main="Philippines: Count vs. when joined")
#plot(x = haiti_info$userjoin, y = haiti_info$node_count, main="Haiti: Count vs. when joined")

#hist(haiti_info$userjoin, breaks='months')

#Important next steps:




