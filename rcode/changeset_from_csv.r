
#Load the data from csv
philippines = read.csv("/Users/jenningsanderson/Google Drive/OSM-Haiti-Philippines-SocialComputing/data/users_changesets/phil_changesets_data.csv")
haiti       = read.csv("/Users/jenningsanderson/Google Drive/OSM-Haiti-Philippines-SocialComputing/data/users_changesets/haiti_changesets_data.csv")

#Combine the two now
phil_info$Country  = "Philippines"
haiti_info$Country = "Haiti"

dat = rbind(phil_info, haiti_info)


#Get some averages, graph them and such...

#Plot them on different things...

#Do all that sort of stuff...

#All from a single dataframe -- no longer call Mongo for just this stuff...