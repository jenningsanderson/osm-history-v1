Ruby Code for Processing Data
=============================
This directory contains all of the Ruby code needed for handling the fileio, processing, exporting, and analytics of the OSM-history data.

For the most part, the files here are separated out into _individual scripts_ that connect to Mongo and do something (either import, export, or process)

There are some Ruby dependencies in these scripts, so be sure to run 

	bundle install

to install the dependencies listed in the gem file.

###Key Files
```osm_history_analysis.rb``` Contains the **OSMHistoryAnalysis** class.  Most files require this file (```require_relative '../osm_history_analysis')``` and instantiate the class to access certain attributes (such as a Mongo connection)

Hopefully the directory structure is relatively straightforward -- here's a breakdown of what's here:

###analysis/
These scripts each connect to Mongo and perform some type of analysis and typically export some type of datafile: ```csv```, ```geojson```, or ```kml```


###import_scripts/
Hopefully these needn't be run again