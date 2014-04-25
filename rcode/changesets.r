# Attempting to visualize this data with R

# install package to connect through monodb
# install.packages("rmongodb")
library(rmongodb) #Loads the mongodb library

# Connect to MongoDB
mongo = mongo.create(host = "epic-analytics.cs.colorado.edu:27018")
mongo.is.connected(mongo)

# Show the databases available (each is a specific region)
# mongo.get.databases(mongo)

# Show the collections available
# mongo.get.database.collections(mongo, db = "haiti")

# Query for the data we want:
query = mongo.bson.buffer.create()
startDate <- ISOdate(2010,01,12)
endDate <- ISOdate(2010,02,12)
mongo.bson.buffer.start.object(query, "created_at")
mongo.bson.buffer.append(query, "$gt", startDate)
mongo.bson.buffer.append(query, "$lt", endDate)
mongo.bson.buffer.finish.object(query)
query = mongo.bson.from.buffer(query)

# define the fields we want
fields = mongo.bson.buffer.create()
mongo.bson.buffer.append(fields, "uid", 1L)
mongo.bson.buffer.append(fields, "node_count", 1L)
mongo.bson.buffer.append(fields, "node_density", 1L)
mongo.bson.buffer.append(fields, "created_at", 1L)
mongo.bson.buffer.append(fields, "area", 1L)
mongo.bson.buffer.append(fields, "_id", 0L)
fields = mongo.bson.from.buffer(fields)

## create the namespace
DBNS= "haiti.changesets"

#Count the number of records in the namespace
size <- mongo.count(mongo, ns = DBNS, query)

pb <- txtProgressBar(min = 0, max = size, style = 3)

#Create the cursor
cursor = mongo.find(mongo, ns=DBNS, query=query, fields=fields)

## iterate over the cursor
changesetInfo = data.frame(stringsAsFactors = FALSE)
i <- 0
while(mongo.cursor.next(cursor)){
  #Read the value
  tmp = mongo.bson.to.list(mongo.cursor.value(cursor))
  # Add it to the dataframe
  changesetInfo = rbind.fill(changesetInfo, as.data.frame(tmp))
  #Show the status message
  i = i+1
  setTxtProgressBar(pb, i)
}
close(pb)

hist(log(changesetInfo$node_count, base=10), col='blue', main="Frequency of Changesets with #Nodes", xlab="Log_10 Node Count", ylab="Freq")
hist(log(changesetInfo$node_density, base=10), col='red', main="Frequency of Nodes/Area", xlab="Log_10 Changeset Count", ylab="Freq"))
hist(log(changesetInfo$node_density, base=10), col='red', main="Frequency of Area Size (Sq. km", xlab="Log_10 Changeset Count", ylab="Freq"))

