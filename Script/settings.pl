$cwd = getcwd();

 $filename = "japan"; #the map to create: you need a $filename.poly and a $filename-latest.osm.bz2 in rawdata
 $tempdir = "$cwd/temp/";	#osmosid temp files are stored here
 $manualcleenup=0;		#temp file will not be emptied after completion if you set this
 $usehdd = 1; 				#uses hdd space instead of RAM; standard is on as it is the saver option; switching this off will require free RAM of at least the size of the OSM file and the java options (below) set accordingly


 $contour=1;	# setting contour=1 gives you the contour map
 $countourstepsminor=50; # every x meters a minor contour line is drawn
 $countourstepsmedium =100;
 $countourstepsmajor=250;


#settings for osmosis
 $JAVACMD_OPTIONS="-d64 -Djava.io.tmpdir=\"$tempdir\" -Xmx3000m";	#the JVM options: use 64bit java for more available RAM; set the temp dir and allow 3Gig of RAM to be used
 $osmosishome = "$cwd/osmosis/";