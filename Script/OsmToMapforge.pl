use Win32::Console::ANSI;
use Term::ANSIColor;
use Cwd;
use File::HomeDir;
use File::Copy;
use File::Path;
use File::stat;
use POSIX;


system("cls");

print colored ["bold green on_blue"],"==> OSM to MapForge Converter <==";
print "\n\n";

#get the settings
require './settings.pl';


#
#
#
#and go!
#
#
#

#
#check for mapforge plugin
#
my $home = $ENV{ APPDATA };

my $pluginpath = "$home/Openstreetmap/Osmosis/Plugins/mapsforge-map-writer.jar";

if (-e $pluginpath)
{
	print colored ["bold blue on_black"], "Mapforge plugin found: overwriting\n";
 } 
 else
 {
 	print "Mapforge plugin not found @ $pluginpath\n\tTrying to copy\n\tto $plugindestination\n";
	}
	my $pluginsource ="$cwd/jars/mapsforge-map-writer.jar";
	my $plugindestination ="$home/Openstreetmap/Osmosis/Plugins/mapsforge-map-writer.jar";
	print "Plugin not found @ $pluginpath\n\tTrying to copy\n\tto $plugindestination\n";
	mkpath("$home/Openstreetmap/Osmosis/Plugins/");
	
	if(!copy($pluginsource,$plugindestination))
	{
		print colored ["red"] ,"\tfailed copying file\n\tIs the JAR @ cwd/jars/mapsforge-map-writer.jar ?";
		print "\n";
		exit;
	}
	else
	{
		print "\tDone.\n"

 }

 #
 #check dirs
 #
 if (! -d $tempdir)
{
	if(!mkpath($tempdir))
	{
		print colored ["red"] ,"failed creating temp dir";
		print "\n";
		exit;
	}
}

if(!isDirEmpty($tempdir)&&!($manualcleenup ==1))
{
	print colored ["bold red"] ,"Temp directory is not empty.\n\tPlease delete existing files or set the 'manualcleanup' option.";
	print "\n";
	exit;
}

if (! -d "$cwd/maps/")
{
	if(!mkpath("$cwd/maps/"))
	{
		print colored ["bold red"] ,"failed creating maps dir";
		print "\n";
		exit;
	}
}

if (! -d "$cwd/stepresults/")
{
	if(!mkpath("$cwd/stepresults/"))
	{
		print colored ["bold red"] ,"failed creating stepresults dir";
		print "\n";
		exit;
	}
}

if (! -d "$cwd/rawdata/")
{
	if(!mkpath("$cwd/rawdata/"))
	{
		print colored ["bold red"] ,"failed creating rawdata dir";
		print "\n";
		exit;
	}
}

#
#check files
#
if (-e "$cwd/rawdata/$filename.poly")
{
	print colored ["bold blue on_black"], "Polygon file found\n";
 } 
 else
 {
	print colored ["bold red"] , "Polygon file missing (\./rawdata/$filename.poly)" ;
	print "\n";
	exit;
 }

 if (-e "$cwd/rawdata/$filename-latest.osm.bz2")
{
	print colored ["bold blue on_black"], "Map source file found\n";
 } 
 else
 {
	print colored ["bold red"] , "Map source file missing (\./rawdata/$filename-latest.osm.bz2)" ;
	print "\n";
	exit;
 }

#get bounding box
@bbox = getBoundingBox("$cwd/rawdata/$filename.poly");
	
#make maps
if($contour)
{
	print "\nCreating contour maps for ";
	print colored ["bold green on_black"] ,"$filename";
	print " with stepwidth "; 
	print colored ["bold green on_black"] ,"$countourstepsmajor / $countourstepsmedium / $countourstepsminor";
	print " meters";
	print "\n\n";
	
	my $filecount = 0;
	
	#
	#SRTM
	#
	if (! -e "$cwd/Srtm2Osm/Srtm2Osm.exe")
	{
		print colored ["red"] ,"./Srtm2Osm/Srtm2Osm.exe not found";
		print "\n";
		exit;
	}
	
	if(-e "$cwd/stepresults/$filename\_$countourstepsmajor-$countourstepsmedium-$countourstepsminor\_srtm.osm" )
	{
		print colored ["green"] , "fitting srtm map found .. skipping" ;
		print "\n";
	}
	else
	{
		print colored ["green"] , "creating srtm map" ;
		print "\n";
		my $srtmcommand = sprintf("$cwd/Srtm2Osm/Srtm2Osm.exe -step $countourstepsminor -cat $countourstepsmajor $countourstepsmedium -maxwaynodes 255 -bounds1 %.5f %.5f %.5f %.5f -o $cwd/stepresults/$filename\_$countourstepsmajor-$countourstepsmedium-$countourstepsminor\_srtm.osm",$bbox[1], $bbox[0], $bbox[3] ,$bbox[2]);
		#print($srtmcommand);
		my $retVal =system($srtmcommand) ;
		#print colored ["red"] ,"srtm data $retVal";
		if ($retVal !=0)
		{
			print colored ["red"] ,"failed creating srtm data";
			print "\n";
			exit;
		}
		$filecount++;
	}
			

	#
	#merge to map
	#
	if(  (-e "$cwd/stepresults/$filename\_$countourstepsmajor-$countourstepsmedium-$countourstepsminor\_merged.osm.bz2") && ( stat("$cwd/rawdata/$filename-latest.osm.bz2" )->mtime < stat("$cwd/stepresults/$filename\_$countourstepsmajor-$countourstepsmedium-$countourstepsminor\_merged.osm.bz2")->mtime))
	{
		print colored ["green"] , "current merged file found.. skipping" ;
		print "\n";
	}
	else
	{		
		print colored ["green"] , "merging srtm to map" ;
		print "\n";
		
		#$cwd/rawdata/$filename-latest.osm.bz2
		my $osmosissettings = "--rx  $cwd/rawdata/$filename-latest.osm.bz2 --sort --rx $cwd/stepresults/$filename\_$countourstepsmajor-$countourstepsmedium-$countourstepsminor\_srtm.osm --sort --merge --wx $cwd/stepresults/$filename\_$countourstepsmajor-$countourstepsmedium-$countourstepsminor\_merged.osm.bz2";
		runOsmosis($osmosishome,$JAVACMD_OPTIONS,$osmosissettings);
		$filecount++;
	}

	#
	#calc mapforge map
	#
	if(  (-e "$cwd/maps/$filename\_c\_$countourstepsmajor-$countourstepsmedium-$countourstepsminor.map") && ( stat("$cwd/rawdata/$filename-latest.osm.bz2" )->mtime < stat("$cwd/maps/$filename\_c\_$countourstepsmajor-$countourstepsmedium-$countourstepsminor.map")->mtime))
	{
		print colored ["green"] , "current map file found.. skipping" ;
		print "\n";
	}
	else
	{
		print colored ["green"] , "creating map" ;
		print "\n";
		my $hddtag = "";
		
		if($usehdd)
		{
			$hddtag = "type=hdd";
		}
		my $osmosissettings = "--read-xml file=$cwd/stepresults/$filename\_$countourstepsmajor-$countourstepsmedium-$countourstepsminor\_merged.osm.bz2 --mapfile-writer file=$cwd/maps/$filename\_c\_$countourstepsmajor-$countourstepsmedium-$countourstepsminor.map tag-conf-file=$cwd/tag-mapping.xml bbox=$bbox[1],$bbox[0],$bbox[3],$bbox[2] $hddtag ";
		runOsmosis($osmosishome,$JAVACMD_OPTIONS,$osmosissettings);
		$filecount++;
	}
	cleenupTemp();
	print colored ["bold green"] , "Done.\nFilename is /maps/$filename\_c\_$countourstepsmajor-$countourstepsmedium-$countourstepsminor.map\nNew Files created: $filecount" ;
	print "\n";
}
else #no contour
{
	print "\nCreating maps "; 
	print colored ["bold green on_black"] ,"$filename without";
	print " contours";
	print "\n\n";
	
	if(  (-e "$cwd/maps/$filename.map") && ( stat("$cwd/rawdata/$filename-latest.osm.bz2" )->mtime < stat("$cwd/maps/$filename.map")->mtime))
	{
		print colored ["green"] , "current map file found.. skipping" ;
		print "\n";
	}
	else
	{		
		print colored ["green"] , "creating map" ;
		print "\n";
		my $hddtag = "";
		
		if($usehdd)
		{
			$hddtag = "type=hdd";
		}
		my $osmosishome = "$cwd/osmosis/";
		my $osmosissettings = "--read-xml file=$cwd/rawdata/$filename-latest.osm.bz2 --mapfile-writer file=$cwd/maps/$filename.map tag-conf-file=$cwd/tag-mapping.xml bbox=$bbox[1],$bbox[0],$bbox[3],$bbox[2] $hddtag ";
		runOsmosis($osmosishome,$JAVACMD_OPTIONS,$osmosissettings);
	}
	cleenupTemp();
	print colored ["bold green"] , "Done.\nFilename is /maps/$filename.map" ;
	print "\n";
}
exit;

#gets the bounding box for SRTM and the mapfilewriter
#adapted from a script written by Frederik Ramm <frederik@remote.org> and released into public domain
sub getBoundingBox()
{
	my $polyfilename ="@_";
	#print colored ["bold blue on_black"], "\nusing $polyfilename for bounding box calculation\n";

	open ($MYFILE, $polyfilename);
	my $maxx = -360;
	my $maxy = -360;
	my $minx = 360;
	my $miny = 360;
	while(<$MYFILE>)
	{
	   if (/^\s+([0-9.E+-]+)\s+([0-9.E+-]+)\s*$/)
	   {
		   my ($x, $y) = ($1, $2);
		   $maxx = $x if ($x>$maxx);
		   $maxy = $y if ($y>$maxy);
		   $minx = $x if ($x<$minx);
		   $miny = $y if ($y<$miny);
	   }
	}
	close ($MYFILE); 
	#print color "bold blue on_black" ;
	#printf "%f,%f,%f,%f\n",$miny,$minx, $maxy, $maxx;
	#print color "white on_black" ;
	@retVal = ($minx , $miny , $maxx , $maxy);
	return @retVal;
}

#this is what the osmosis script usually does
sub runOsmosis()
{
	my $MYAPP_HOME = @_[0];   #where osmosis sits
	my $JAVACMD_OPTIONS = @_[1];    #Java options
	my $osmosisopts =@_[2];		#what osmosis should do
    #print colored["bold blue"],$osmosisopts."\n";

	my $MAINCLASS="org.codehaus.classworlds.Launcher";
	my $PLEXUS_CP="$MYAPP_HOME/lib/default/plexus-classworlds-2.4.jar/";
	print "$MYAPP_HOME/lib/default/\n";
	
	if (! -d "$MYAPP_HOME/lib/default/")
	{
		print colored ["red"] ,"Osmosis not found\nPlease install to ./osmosis/";
		print "\n";
		exit;
	}
	
	my $exec ="java $JAVACMD_OPTIONS -cp $PLEXUS_CP -Dapp.home=\"$MYAPP_HOME\" -Dclassworlds.conf=\"$MYAPP_HOME/config/plexus.conf\" $MAINCLASS $osmosisopts";
	my $result = system($exec);
	
	if ($result !=0)
	{
		print colored ["red"] ,"failed running osmosis";
		print "\n";
		exit;
	}
}

sub isDirEmpty()
{
    my $dirname = shift;
    opendir(my $dh, $dirname) or die "Not a directory: $dirname";
    return scalar(grep { $_ ne "." && $_ ne ".." } readdir($dh)) == 0;
}


sub cleenupTemp()
{
	if(!(manualcleenup ==1))
	{
		print colored ["bold blue"] , "cleening up temp dir" ;
		print "\n";
		unlink (glob( "$tempdir/*.*"));	
	}
	else
	{
		print colored ["bold yellow"] , "manualcleenup selected\ntemp directory may still contain residues" ;
		print "\n";
	}
}





