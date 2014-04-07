OSM-History
===========

Documenting our work here.  Goal is to write ruby scripts to automate some of this.  In the meantime we can document individual steps.

Useful tutorial: https://github.com/MaZderMind/osm-history-renderer/blob/master/TUTORIAL.md

# Part I
_Obtaining history data and clipping it to area of interest_
## Finding History Data
- Grab .pbf files for area of interest from: http://osm.personalwerk.de/full-history-extracts/latest/

## Clipping Data to Just Your Area of Interest

- This process depends on having the Osmium Framework - git clone https://github.com/osmcode/libosmium - and OSM Binary - git clone https://github.com/scrosby/OSM-binary - installed  
- Note that Osmium has a number of dependencies required for the software to work.  See the project readme for details
- If you're getting error messages installing Osmium on Mac, see this: https://gist.github.com/tmcw/7223147
- Now you can set up osm-history-splitter: git clone https://github.com/MaZderMind/osm-history-splitter
- There are a number of options for getting the bounding box (geographic extents) for the area you are interested in.  Easy option is to visit: http://boundingbox.klokantech.com/
- Follow the directions in the OSM History Splitter tool to create your settings file clip your data to just the bounding box specified


# Part II
_Importing history data into MongoDB_
## Installing and Configuring Mongo

- download from: http://www.mongodb.org/downloads
- unzip to applications folder
- symlink from usr/bin to applications/mongodb/bin the following: mongod, mongo, mongoimport, mongoexport
- For full instructions on gettings started OSX see: http://docs.mongodb.org/manual/tutorial/install-mongodb-on-os-x/
- play with this to get started using mongo: http://try.mongodb.org/

## Set up Other Tools

- brew install protobuf-c (mac)
- brew install zlib (mac)
- gem install  mongo
- gem install  pbf_parser
- gem install  bson_ext
- For full instructions on OSX see: http://docs.mongodb.org/manual/tutorial/install-mongodb-on-os-x/

## Importing Data into Mongo

- rename file extension from .osh.pbf to .osm.pbf
- ruby read_pbf.rb $DBNAME $PATHTODATA [limit=4 port=27018 host=localhost]

  Where limit, port, host are optional arguments.  On epic-analytics, please be sure to use port=27018 so as not to use the same mongo instance as EPIC.  The limit argument is for testing, it will only parse the first _limit_ nodes, ways, rels from each block of the PBF file.  Leaving these arguments off will default to no limit, localhost, 27017 (default mongod port)



#Part III
_Using the framework for ..._
## Basic Queries

- changesets by user
- changesets by time
- objects by user
- objects by time
- tags by count
- total nodes, ways, relations by time

## Exporting Queries



## Grabbing User Data

Overpass
