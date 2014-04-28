# Attempting to visualize this data with R

library(rmongodb) # Loads the mongodb library
library(plyr)     # Need this for a dataframe

# Connect to MongoDB
#mongo = mongo.create(host = "epic-analytics.cs.colorado.edu:27018")
mongo = mongo.create(host = 'localhost')
mongo.is.connected(mongo)


# Get our cursor
timeboxed_cursor <- function(startDate, endDate, DBNS, q_limit=500000){
  
  # First, define the query
  query = mongo.bson.buffer.create()
  #startDate <- ISOdate(2010,01,12)
  #endDate <- ISOdate(2010,02,12)
  mongo.bson.buffer.start.object(query, "created_at")
  mongo.bson.buffer.append(query, "$gt", startDate)
  mongo.bson.buffer.append(query, "$lt", endDate)
  mongo.bson.buffer.finish.object(query)
  query = mongo.bson.from.buffer(query)
  
  # Next, define the fields we want for our dataframe
  fields = mongo.bson.buffer.create()
  mongo.bson.buffer.append(fields, "uid", 1L)
  mongo.bson.buffer.append(fields, "node_count", 1L)
  mongo.bson.buffer.append(fields, "node_density", 1L)
  mongo.bson.buffer.append(fields, "created_at", 1L)
  mongo.bson.buffer.append(fields, "area", 1L)
  mongo.bson.buffer.append(fields, "_id", 0L)
  fields = mongo.bson.from.buffer(fields)
  
  cursor = mongo.find(mongo, ns=DBNS, query=query, fields=fields, limit=q_limit)
  size <<- mongo.count(mongo, ns=DBNS, query)
  return(cursor)
}

buildChangeset <- function(cursor){
  changesetInfo = data.frame(stringsAsFactors = FALSE)
  pb <- txtProgressBar(min = 0, max = size, style = 3)
  i <- 0
  
  test_arr <- array(0, c(1,5,size))
  
  while(mongo.cursor.next(cursor)){
    #Read the value
    tmp = mongo.bson.to.list(mongo.cursor.value(cursor))
    
    test_arr[i] <- tmp
    # Add it to the dataframe
    #changesetInfo = rbind.fill(changesetInfo, as.data.frame(tmp))
    #Show the status message
    i = i+1
    setTxtProgressBar(pb, i)
  }
  close(pb)
  return(changesetInfo)
}

# Testing my functions

cursor = timeboxed_cursor(ISOdate(2010,01,12), ISOdate(2010,02,12), 'haiti.changesets', q_limit=10)
info = buildChangeset(cursor)

hist(log(info$node_count, base=10), col='blue', main="Haiti: Frequency of Changesets with #Nodes", xlab="Log_10 Node Count", ylab="Freq")
hist(log(info$node_density, base=10), col='red', main="Haiti: Frequency of Nodes/Area", xlab="Log_10 Changeset Count", ylab="Freq")
hist(log(info$area, base=10), col='purple', main="Haiti: Frequency of Area Size (Sq. km)", xlab="Log_10 Changeset Count", ylab="Freq")
hist(info$created_at, breaks='day', col='orange', main="Haiti: Times of Edits", xlab="When", ylab="Changesets")


