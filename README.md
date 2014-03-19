OSM-History
===========

Documenting our work here.  Goal is to write ruby scripts to automate some of this.  In the meantime we can document individual steps.

## Installing and Configuring Mongo

- download from: http://www.mongodb.org/downloads
- unzip to applications folder
- symlink from usr/bin to applications/mongodb/bin the following: mongod, mongo, mongoimport, mongoexport
- For full instructions on gettings started OSX see: http://docs.mongodb.org/manual/tutorial/install-mongodb-on-os-x/ 
- play with this to get started using mongo: http://try.mongodb.org/ 

## Set up Other Tools

- brew install protobuf-c
- gem install  mongo
- gem install  pbf_parser
- gem install  bson_ext
- For full instructions on OSX see: http://docs.mongodb.org/manual/tutorial/install-mongodb-on-os-x/

## Getting History Data

- Grab .pbf files for area of interest from: http://osm.personalwerk.de/full-history-extracts/latest/
- rename file extension from .osh.pbf to .osm.pbf

## Clipping Data to Just Your Area of Interest

- This process depends on having the Osmium Framework - git clone https://github.com/osmcode/libosmium - and OSM Binary - git clone https://github.com/scrosby/OSM-binary - installed  
- Note that Osmium has a number of dependencies required for the software to work.  See the project readme for details
- Now you can set up osm-history-splitter: git clone https://github.com/MaZderMind/osm-history-splitter 
- There are a number of options for getting the bounding box (geographic extents) for the area you are interested in.  Easy option is to visit: http://boundingbox.klokantech.com/ 
- Follow the directions in the OSM History Splitter tool to clip your file

## Importing Data into Mongo

- create a new collection -
- import your data -

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
