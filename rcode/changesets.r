# Attempting to visualize this data with R

library(rmongodb) # Loads the mongodb library
library(plyr)     # Need this for a dataframe

# Connect to MongoDB
#mongo = mongo.create(host = "epic-analytics.cs.colorado.edu:27018")
mongo = mongo.create(host = "localhost")
mongo.is.connected(mongo)

# Get the cursor
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
  
  cursor <- mongo.find(mongo, ns=DBNS, query=query, fields=fields, limit=q_limit, options=mongo.find.exhaust)
  size <<- mongo.count(mongo, ns=DBNS, query)
  return(cursor)
}

# Attempting to improve performance: http://stackoverflow.com/questions/11561856/add-new-row-to-dataframe
#insertRow <- function(existingDF, newrow, r) {
  existingDF[seq(r+1,nrow(existingDF)+1),] <- existingDF[seq(r,nrow(existingDF)),]
  existingDF[r,] <- newrow
  existingDF
}


buildChangeset <- function(cursor){
  # Start the dataframe here
  mongo.cursor.next(cursor) # Populate dataframe with first value
  tmp = mongo.bson.to.list(mongo.cursor.value(cursor))
  changesetInfo = data.frame(stringsAsFactors = FALSE)
  changesetInfo = rbind.fill(changesetInfo, as.data.frame(tmp))
  
  pb <- txtProgressBar(min = 0, max = size, style = 3)
  i  <- 1
  
  while(mongo.cursor.next(cursor)){
    #Read the value & Use the faster function to add to dataframe
    newrow = as.data.frame(mongo.bson.to.list(mongo.cursor.value(cursor)))
    #changesetInfo = insertRow(changesetInfo, newrow, 1)
    changesetInfo = rbind.fill(changesetInfo, newrow) #This is a slow function, but I don't know a better way to do it
    # Show the status message
    i = i+1
    setTxtProgressBar(pb, i)
  }
  close(pb)
  return(changesetInfo)
}

buildChangeset2 <- function(cursor){
  dt <- data.table(uid=rep("0",size),
                   node_count=rep(0,size),
                   created_at=rep("NA",size),
                   node_density=rep(0,size),
                   area=rep(0,size))
  i <- 1
  while (mongo.cursor.next(cursor)) {
    b <- mongo.cursor.value(cursor)
    set(dt, i, 1L,  mongo.bson.value(b, "uid"))
    set(dt, i, 2L,  mongo.bson.value(b, "node_count"))
    set(dt, i, 3L,  mongo.bson.value(b, "node_density"))
    set(dt, i, 4L,  mongo.bson.value(b, "created_at"))
    set(dt, i, 5L,  mongo.bson.value(b, "area"))
    i <- i+1
  }
  return(dt)
}

# Testing my functions
cursor = timeboxed_cursor(ISOdate(2010,01,12), ISOdate(2010,02,12), 'haiti.changesets')
info = buildChangeset2(cursor)

#hist(log(info$node_count, base=10), col='blue', main="Haiti: Frequency of Changesets with #Nodes", xlab="Log_10 Node Count", ylab="Freq")
#hist(log(info$node_density, base=10), col='red', main="Haiti: Frequency of Nodes/Area", xlab="Log_10 Changeset Count", ylab="Freq")
#hist(log(info$area, base=10), col='purple', main="Haiti: Frequency of Area Size (Sq. km)", xlab="Log_10 Changeset Count", ylab="Freq")
#hist(info$created_at, breaks='day', col='orange', main="Haiti: Times of Edits", xlab="When", ylab="Changesets")


