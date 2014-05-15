Changeset Analysis
========================================================
Looking at OSM changeset density

Part 0: Define custom functions

```r
# Allow for normalization of date
adjustDate <- function(dataframe, date) {
    dataframe$DaysSinceEvent = as.numeric(as.Date(dataframe$date) - as.Date(date))
    return(dataframe)
}

# This function returns 0 if x is less than zero instead of calculating the
# log
custom_log <- function(x) ifelse(x <= 0, 0, base::log(x))  #Redefine log to return 0 when undefined...
```


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




### Comparing Node Counts
Notice that there is a large spike in the Philippines at 4 nodes per changeset.  A simple building is typically comprised of exaclty 4 nodes.  The working hypothesis here is that each of these changesets represents a building and that buildings were mapped in the Philippines because the road structure was already in place; whereas in Haiti, the road system was not yet in place.

![plot of chunk comparing_node_counts](figure/comparing_node_counts.png) 



### Lorenz curves for the amount of nodes
![plot of chunk lorenz_curves](figure/lorenz_curves.png) 



### Count users that edited in both sets:

```r
length(intersect(philippines$user, haiti$user))
```

```
## [1] 54
```


### Plot Node count vs area

```r
ggplot(data = dat_lim, aes(x = log(node_count), y = custom_log(density), color = Country)) + 
    geom_point(shape = 19, alpha = 1/2) + stat_smooth(method = "lm", size = 1)
```

![plot of chunk unnamed-chunk-4](figure/unnamed-chunk-4.png) 


### Plot Node count vs area

```r
ggplot(data = dat_lim, aes(x = log(area), y = custom_log(density), color = Country)) + 
    geom_point(shape = 19, alpha = 1/2) + stat_smooth(method = "lm", size = 1)
```

```
## Error: argument is of length zero
```


### Histogram of densities

```r
ggplot(dat_lim, aes(log(density), fill = Country)) + geom_histogram(alpha = 0.5, 
    binwidth = 0.1, position = "identity")
```

![plot of chunk unnamed-chunk-5](figure/unnamed-chunk-5.png) 


### What about just density overtime?

```r
# ggplot(data=dat_lim, aes(x = DaysSinceEvent, y = log(density),
# color=Country) ) + geom_point(shape=19, alpha=1/2) + stat_smooth(method =
# 'loess', size = 1)
```



### Plotting Node Density against user joining date

```r
# Plot them against eachother: ggplot(aes(x = userjoin, y =
# log(node_density), color=Country), data=dat) +
# geom_point(shape=19,alpha=1/2)
```


