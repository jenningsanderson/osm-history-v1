OSM-History
===========

Documenting our work here.  Goal is to write ruby scripts to automate some of this.  In the meantime we can document individual steps.

## Installing and Configuring Mongo

- download from: http://www.mongodb.org/downloads
- unzip to applications folder
- symlink from usr/bin to applications/mongodb/bin the following: mongod, mongo, mongoimport, mongoexport

- For full instructions on OSX see: http://docs.mongodb.org/manual/tutorial/install-mongodb-on-os-x/

## Getting History Data

- Grab .pbf files for area of interest from: http://osm.personalwerk.de/full-history-extracts/latest/
- rename file extension from .osh.pbf to .osm.pbf

## Importing Data into Mongo

- create a new collection -
- import your data -

## Setting up your bounding box


## Basic Queries

- changesets by user
- changesets by time
- objects by user
- objects by time
- tags by count
- total nodes, ways, relations by time

## Exporting Queries


## Grabbing User Data

Overpass?
