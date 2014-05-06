Changeset Analysis
========================================================
Looking at OSM changeset density


Part 1: Load the Data
-------------------------------------------------------



1. Load the entire Data from the disaster window CSV





2. Load some small sample data, this is data from 25 random users in each data set.





3. For more data, load a larger sample: 75 users from each set.




### Summary Statistics of the data
Philippines

```r
summary(philippines$node_count)
summary(philippines$area)
summary(philippines$density)
```


Haiti

```r
summary(haiti$node_count)
summary(haiti$area)
summary(haiti$density)
```



```r
log <- function(x) ifelse(x <= 0, 0, base::log(x))  #Redefine log to return 0 when undefined...
```



### Plot Node count vs area

```r
ggplot(data = dat, aes(x = log(node_count), y = log(area), color = Country)) + 
    geom_point(shape = 19, alpha = 1/2) + stat_smooth(aes(x = log(node_count), 
    y = log(area), color = Country), method = "lm", formula = y ~ x, size = 1)
```

![plot of chunk another_test](figure/another_test.png) 


### Histogram of densities

```r
ggplot(dat[dat$density > 1, ], aes(log(density), fill = Country)) + geom_histogram(alpha = 0.5, 
    binwidth = 0.1, position = "identity")
```

![plot of chunk unnamed-chunk-6](figure/unnamed-chunk-6.png) 






### What about just density overtime?

```r
ggplot(data = dat[dat$area > 1, ], aes(x = log(area), y = log(density), color = Country)) + 
    geom_point(shape = 19, alpha = 1/2) + stat_smooth(method = "lm", size = 1)
```

![plot of chunk count_v_area](figure/count_v_area.png) 



### Plotting Node Density against user joining date

```r
# Plot them against eachother:
ggplot(aes(x = userjoin, y = log(node_density), color = Country), data = dat) + 
    geom_point(shape = 19, alpha = 1/2)
```

```
## Error: object 'userjoin' not found
```


