# Attempting to visualize this data with R

library(rmongodb) # Loads the mongodb library
library(plyr)     # Need this for a dataframe
library(data.table)

# Connect to MongoDB
mongo = mongo.create(host = "epic-analytics.cs.colorado.edu:27018")
#mongo = mongo.create(host = "localhost")
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

is.not.null <- function(x) ! is.null(x)

buildChangeset <- function(cursor){
  dt <- data.table(uid=rep(NA_integer_, size),
                   node_count=rep(NA_integer_, size),
                   node_density=rep(NA_real_,size),
                   area=rep(NA_real_,size),
                   created_at=rep(Sys.time(),size),
                   userjoin = rep(Sys.time(),size))
  i <- 1L
  pb <- txtProgressBar(min = 0, max = size, style = 3)
  while (mongo.cursor.next(cursor)) {
    
    #Capture the value of the cursor to the variable 'b'
    b <- mongo.cursor.value(cursor)
    
    ## Actually write the values from Mongo to a table -- this is as efficient as it can be -- but wish I coul dynamically code it.
    
    #UID
    uid <- mongo.bson.value(b, "uid")
    if (is.not.null(uid)){
      set(dt, i, 'uid',  uid)
    }
    
    #Node Count
    node_count <- mongo.bson.value(b, "node_count")
    if (is.not.null(node_count)){
      set(dt, i, 'node_count',  node_count)
    }
    
    #Node Density
    node_density <- mongo.bson.value(b, "node_density")
    if (is.not.null(node_density)){
      set(dt, i, 'node_density',  node_density)
    }
    
    #User ID
    area <- mongo.bson.value(b, "area")
    if (is.not.null(area)){
      set(dt, i, 'area',  area)
    }
    
    #Date it was created
    created_at <- mongo.bson.value(b, "created_at")
    if (is.not.null(created_at)){
      set(dt, i, 'created_at',  created_at)
    }
    
    #Date the user joined
    userjoin <- mongo.bson.value(b, "userjoin")
    if (is.not.null(userjoin)){
      set(dt, i, 'userjoin',  userjoin)
    }

    i <- i+1L
    setTxtProgressBar(pb, i)
  }
  return(data.frame(dt))
}




# Testing my functions
#cursor = timeboxed_cursor(ISOdate(2010,01,12), ISOdate(2010,02,12), 'haiti.changesets')
#info = buildChangeset(cursor)

#hist(log(info$node_count, base=10), col='blue', main="Haiti: Frequency of Changesets with #Nodes", xlab="Log_10 Node Count", ylab="Freq")
#hist(log(info$node_density, base=10), col='red', main="Haiti: Frequency of Nodes/Area", xlab="Log_10 Changeset Count", ylab="Freq")
#hist(log(info$area, base=10), col='purple', main="Haiti: Frequency of Area Size (Sq. km)", xlab="Log_10 Changeset Count", ylab="Freq")
#hist(info$created_at, breaks='day', col='orange', main="Haiti: Times of Edits", xlab="When", ylab="Changesets")

#plot(x=log(info$area), y=log(info$node_density), type='p')
#plot(x=info$node_count, y=info$node_density, type='p', xlim=c(0,10000), ylim=c(0,1000000))




# Attempting to improve performance: http://stackoverflow.com/questions/11561856/add-new-row-to-dataframe
# insertRow <- function(existingDF, newrow, r) {
#   existingDF[seq(r+1,nrow(existingDF)+1),] <- existingDF[seq(r,nrow(existingDF)),]
#   existingDF[r,] <- newrow
#   existingDF
# }
# 
# 
# buildChangeset <- function(cursor){
#   # Start the dataframe here
#   mongo.cursor.next(cursor) # Populate dataframe with first value
#   tmp = mongo.bson.to.list(mongo.cursor.value(cursor))
#   changesetInfo = data.frame(stringsAsFactors = FALSE)
#   changesetInfo = rbind.fill(changesetInfo, as.data.frame(tmp))
#   
#   pb <- txtProgressBar(min = 0, max = size, style = 3)
#   i  <- 1
#   
#   while(mongo.cursor.next(cursor)){
#     #Read the value & Use the faster function to add to dataframe
#     newrow = as.data.frame(mongo.bson.to.list(mongo.cursor.value(cursor)))
#     #changesetInfo = insertRow(changesetInfo, newrow, 1)
#     changesetInfo = rbind.fill(changesetInfo, newrow) #This is a slow function, but I don't know a better way to do it
#     # Show the status message
#     i = i+1
#     setTxtProgressBar(pb, i)
#   }
#   close(pb)
#   return(changesetInfo)
# }

