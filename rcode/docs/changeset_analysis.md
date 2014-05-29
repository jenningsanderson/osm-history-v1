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



5. Load only changesets with less than 1000 nodes (and more than 1 node) -- entire set



### Summary Statistics of the data
_Currently not implemented_

Philippines



Haiti



Part 2. Visual Comparison
-------------------------------------
### Comparing Node Counts
Notice that there is a large spike in the Philippines at 4 nodes per changeset.  A simple building is typically comprised of exaclty 4 nodes.  The working hypothesis here is that each of these changesets represents a building and that buildings were mapped in the Philippines because the road structure was already in place; whereas in Haiti, the road system was not yet in place.

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
![plot of chunk changeset_densities_areas](figure/changeset_densities_areas1.png) ![plot of chunk changeset_densities_areas](figure/changeset_densities_areas2.png) ![plot of chunk changeset_densities_areas](figure/changeset_densities_areas3.png) 


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

