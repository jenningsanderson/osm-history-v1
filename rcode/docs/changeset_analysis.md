Changeset Analysis
========================================================

Part 0: Define custom functions



Part 0.1: Load Libraries



Part 1: Load the Data
-------------------------------------------------------



1. Load the entire Data from the disaster window CSV



2. Load some small sample data, this is data from 25 random users in each data set.



3. For more data, load a larger sample: 75 users from each set.



4. Load only changesets with less than 1000 nodes (still has the 1 node)



5. Load only changesets with less than 10000 nodes (and more than 1 node) -- entire set



### Summary Statistics of the data
_Currently not implemented_

Philippines



Haiti



Part 2. Visual Comparison
-------------------------------------
### Comparing Node Counts
Notice that there is a large spike in the Philippines at 4 nodes per changeset.  A simple building is typically comprised of exaclty 4 nodes.  The working hypothesis here is that each of these changesets represents a building and that buildings were mapped in the Philippines because the road structure was already in place; whereas in Haiti, the road system was not yet in place.


```
## pdf 
##   2
```

![plot of chunk comparing_node_counts](figure/comparing_node_counts.png) 



### Lorenz curves for the amount of nodes
![plot of chunk lorenz_curves](figure/lorenz_curves.png) 



### Count users that edited in both sets:

```
## [1] 54
```


### Getting an idea for WHEN the edits occur

```
## pdf 
##   2
```


### Looking at Changeset Density & Area
The following results are normalized to 1, so that they can be compared side-by-side.  The breaks are .25, so the sum of the area is 4.

```
## pdf 
##   2
```

```
## pdf 
##   2
```


### Plot User contributions by day since the event

```r
# Load the CSV that's printed from ruby
haiti_by_day_contributions = read.csv("/Users/jenningsanderson/osm-history/ruby/csv_exports/haiti_top_20_user_node_count_by_day.csv")
ggplot(haiti_by_day_contributions, aes(x = DaysSinceEvent, y = NodeCount, color = User)) + 
    geom_line() + scale_fill_brewer(palette = "Paired") + xlab("Days Since Event") + 
    ylab("Nodes Edited Each Day") + ggtitle("Haiti User Activity per day since Event")
```

![plot of chunk haiti_nodes_by_user](figure/haiti_nodes_by_user.png) 



```r
# Load the CSV that's printed from ruby
phil_by_day_contributions = read.csv("/Users/jenningsanderson/osm-history/ruby/csv_exports/phil_top_20_user_node_count_by_day.csv")
ggplot(phil_by_day_contributions, aes(x = DaysSinceEvent, y = NodeCount, color = User)) + 
    geom_line() + scale_fill_brewer(palette = "Blues") + xlab("Days Since Event") + 
    ylab("Nodes Edited Each Day") + ggtitle("Philippines User Activity per day since Event")
```

![plot of chunk phil_nodes_by_user](figure/phil_nodes_by_user.png) 


### User contribution charts

```r
phil_user_contributions  = read.csv("/Users/jenningsanderson/osm-history/ruby/csv_exports/edits_per_user_philippines.csv")
haiti_user_contributions = read.csv("/Users/jenningsanderson/osm-history/ruby/csv_exports/edits_per_user_haiti.csv")

hist(phil_user_contributions$edits)
```

![plot of chunk user_contribution_charts](figure/user_contribution_charts1.png) 

```r
hist(haiti_user_contributions$edits)
```

![plot of chunk user_contribution_charts](figure/user_contribution_charts2.png) 

```r

png("/Users/jenningsanderson/Dropbox/OSM_Behavioral_Analysis_CSCW/Images/user_edits_philippines.png", width=800, height=400)
plot(y=(sort(phil_user_contributions$edits, decreasing=T)), x=seq(1,length(phil_user_contributions$user)), pch=20,
     log='y', xlab="Individual Users", ylab="Number of Edits", main="Philippines: Number of Edits per user",
     cex.main=2, cex.axis=1.2, cex.lab=1.2)
abline(h=median(phil_user_contributions$edits),col=4,lty=2)
abline(h=mean(phil_user_contributions$edits),col=2,lty=2)
legend("topright",#x=380,y=50000,      # places a legend at the appropriate place 
    	 c("Mean","Median"),  # puts text in the legend 
       lty=c(2,2),        # gives the legend appropriate symbols
       col=c(2,4),
       cex=1.3)
dev.off()
```

```
## pdf 
##   2
```

```r

png("/Users/jenningsanderson/Dropbox/OSM_Behavioral_Analysis_CSCW/Images/user_edits_haiti.png", width=800, height=400)
plot(y=(sort(haiti_user_contributions$edits, decreasing=T)), x=seq(1,length(haiti_user_contributions$user)), pch=20,
     log='y', xlab="Individual Users", ylab="Number of Edits", main="Haiti: Number of Edits per user",
     cex.main=2, cex.axis=1.2, cex.lab=1.2)
abline(h=median(haiti_user_contributions$edits),col=4,lty=2)
abline(h=mean(haiti_user_contributions$edits),col=2,lty=2)
legend("topright",#x=380,y=50000,      # places a legend at the appropriate place 
  		 c("Mean","Median"),  # puts text in the legend 
       lty=c(2,2),        # gives the legend appropriate symbols
       col=c(2,4),
       cex=1.3)
dev.off()
```

```
## pdf 
##   2
```

```r

users_in_both <- intersect(haiti_user_contributions$user, phil_user_contributions$user)

haiti_intersect <-haiti_user_contributions[haiti_user_contributions$user %in% users_in_both,]
phil_intersect <-phil_user_contributions[phil_user_contributions$user %in% users_in_both,]

sorted_haiti_intersect <- with(haiti_intersect,  haiti_intersect[order(user),])
sorted_phil_intersect  <- with(phil_intersect, phil_intersect[order(user),])

sorted_haiti_intersect$phil_edits = sorted_phil_intersect$edits

#Now sort it by a different column
to_plot <- with(sorted_haiti_intersect, sorted_haiti_intersect[order(-edits),])

plot(x=seq(1,length(to_plot$user)), y=to_plot$phil_edits, log='y')
lines(x=seq(1,length(to_plot$user)), y=to_plot$edits)
```

![plot of chunk user_contribution_charts](figure/user_contribution_charts3.png) 

```r

#mean(haiti_intersect$edits)
#mean(phil_intersect$edits)
```

