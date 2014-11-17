osm-to-mapforge
===============

OSM to Mapforge converter script


# Introduction

   After using C:Geo for a while I wanted to update my maps. Unfortunately the guys from the Mapsforge project didn't update theirs.
   While trying to convert OSM maps by myself I came across a) a little perl script from Frederik Ramm that got the bounding box from the polygon files and b) SRTM.

   I started expanding the script until I got something that could turn a OSM extract into a mapsforge map and optionally add in contour lines.
   
   It would be a waste to keep this just for myself so I put it up on github.
   
# Files / Setup

  There are two versions of the script bundle. 
  
   - The all-in-one package that includes the scripts, Osmosis(0.40.1), a matching Mapforge plugin(0.3.0) and Srtm2Osm(1.12.1.0).
   	- tested to produce working maps
   	- trust the me at your own risk
   - the paranoid version just has the scriptsand the XML for the contour lines, you will have to add the rest yourself

##  All In One
 - you will need Perl so install that
 - Java is also needed 
 - extract the package to a directory and you're done
	 
## Paranoid
 - you will need Perl so install that
 - Java is also needed
 - extract the package to a directory
 - get Osmosis and extract it in the osmosis path keeping the structure
 - get a matching mapsforge mapwriter plugin, rename it to 'mapsforge-map-writer.jar' and place it in the jar folder; you WILL get errors if the plugin doesn't match the used osmosis version
 - get Srtm2Osm and extract it to the Srtm2Osm folder
	  
	  
# Usage
   - you will need:
     - a packed OSM extract named [country]-latest.osm.bz2
     - polygon file for these extract named [country].poly
	 (those from [geofabrik](http://www.geofabrik.de) have this format)
   - place these in the folder rawdata
   - open settings.pl in an editor and change to your liking
   - run OsmToMapforge.pl
   
   
# Limitations
 - your time: the bigger the area you want to create the longer it takes. If you merge in contours first it takes even longer. Long as in 'multiple days'
 - memory and storage: if you didn't change the options osmosis will write its temporary files to disk. They usually reach the size of the uncompressed OSM extract.
 - ~~Srtm2Osm:the current version of Srtm2Osm has a bug that occurs if large areas are used; there is already a fix underway that uses hdd space if this would happen~~
 - As the script was only written for myself it is only tested on a Win7 64bit machine

# Legal stuff
  - For the All-In-One package: 
    - the packed tools have their own license that can be found in the respective directories.
  - For the script itself see LICENSE