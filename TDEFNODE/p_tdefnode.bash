#!/bin/bash

version="1.2"

usage() 
{
	echo ""
	echo "DESCRIPTION: ${0##*/}: plot output of TDEFNODE block model code with GMT5, rewrite of code"
	echo "supplied P. Vernant, 2008-2012"
	echo "Mencin/Vernant 2015"
	echo "Version:$version"
  	echo ""
	echo "USAGE: ${0##*/} -R|--range [ -topo ....]"
	echo "Will read in .p_tdefnode.defaults with values in the form range='10/15/2/8', priority is	"
	echo "flags override defaults file and defaults file (.p_tdefnode.defaults) overrides defaults." 
	echo ""
	echo "OPTIONS:"
	echo ""
	echo "--range|-R    define the range for graphics, required	-R (token)"
	echo "--verbose|-v  Add verbose flag to GMT statements"
	echo "--proj        Valid GMT5 projection token -J(token)"
	echo "--tick        Valid GMT5 tick token -B (token)"
	echo "--prev|-p     open the plot with preview (OSX) or gs (everything else) after done"
	echo "--help|-h     print this"
	echo "--gmt_velo    --gmt [psvelo  file] plot velocity file (can be repeated)"
	echo "--gmtC_velo   --gmt [psvelo  file] [color] plot velocity file(can be repeated)"
	echo "--gmt_sites   --gmt [lon lat ... file] plot sites from first two columns (can be repeated)"
	echo "--gmtC_sites  --gmt [lon lat ... file] [color] plot sites from first two columns (can be repeated)"
	echo "--gmtZ_sites  --gmt [lon lat ... file] [cpt file] plot sites from first two columns (can be repeated)"
	echo "--gmt_lines   --gmt [lon lat ... file] plot lines from first two columns (can be repeated)"
	echo "--gmtC_lines  --gmt [lon lat ... file] [color] plot lines from first two columns (can be repeated)"
	echo "--gmtZ_lines  --gmt [lon lat ... file] [cpt file] plot lines from first two columns (can be repeated)"
	echo "--rangeS      --rangeS [lon lat ... file] sets range around lon lat plus one degree"
	echo "--out|-o      change name of output file, default is p_tdefnode.out.pdf"
	echo "--prev|--show show the resultins pdf file"
	echo "--bufferR     sets the buffer around the range command (in degrees), must be before and range command"
	echo ""
	echo "topography:"
	echo " --topo           plot the topography"
	echo " --topof file     topography grid file (required if plotting topography)"
	echo " --topog file     topography gradient grid (defaults to -A250 if not supplied)"
	echo " --topo_cpt file  user supplied palette file (defaults to gmt \"globe\" if not supplied)"
	echo " --topo_flat      plot topography without illumination"
	echo " --bw             plot topography with black and white color table"
	echo " --getTopo        Gets the SRTM topography data based on range (you can use any range command to set this)"
	echo "                  This option will check for the existence of a what is supplied by --topof or"
	echo "                  a file called topo.grd or a file that overides this in .p_tdefnodes, this "
	echo "                  defaults to SRTM90"
	echo " --srtm30         with --getTopo gets srtm30 data, this only work for US areas"
	echo ""
	echo "tdefnode model: (run this program in output directory for these flags)"
	echo " --blk            plot block geometry"
	echo " --blkN name      plot a single block with name (can be repeated)"
	echo " --blkn           label blocks with names"
	echo " --blkCoor        print the block nodes in ordinal order (good for debuging your geometry"
	echo " --printB         print block names used in model to stdout and exit"
	echo " --mod            plot model velocity field"
	echo " --obs            plot observed velocity field"
	echo " --res            plot velocity residuals"
	echo " --sites          plot the sites used in the model"
	echo " --sta            plot the names of the sites used in the model"
	echo " --nodes          plots node numbers"
	echo " --nodeN number   plot nodes for fault number"
	echo " --faults         plots all faults"
	echo " --fault number   plot fault number"
	echo " --printF         print fault numbers and names usedin model and exit"
	echo " --faultCoor      print fault nodes in ordinal order"
	echo " --nodeN number   plots the surface nodes of fault for that number (can be repeated)"
	echo " --rangeB name    sets range around block with name plus one degree border"
	echo " --rangeM         sets range around model plus one degree border"
	echo " --rangeF number  sets range around fault with number plus one degree"
	echo ""
	echo "Recognized values in defaults file"
	echo "  range=west/east/south/north 0-360 and -180 180 both work"
	echo "  ps=\"p_tdefnode.out.ps\""
	echo "  src_grd_file=\"dummy.grd\""
	echo "  topog_file=\"topog.grd\""
	echo "  topo_file=\"topo.grd\""
	echo "  cpt_file=\"temp.cpt\""
	echo "  projection=\"M9i\""
	echo "  tick=\"a.5f2nSWe\""
	echo "  srtm_res=\"SRTM90\""
	echo "  src_grd=true this tells us that there is a local source grd for grdcut"
	echo "  src_grd_file=/Users/dmencin/Dropbox/GMT/grdfiles/ETOPO1_Bed_g_gmt4.grd the local grd file for above"
	exit
}

name=${0##*/}

# Test if gmt exists and is greater than version 5
if [ `which gmt` ]
then 
	gmt_version=`gmt --version`
	if [ ${gmt_version:0:1} != "5" ]
	then
		echo "$name: Need GMT version 5."
		exit 1
	fi
else
	echo "$name: GMT5 does not exist or is not in path correctly."
	exit 1
fi

echo "Starting... $name"

# Set defaults
rbuf=1
topo=false
topo_flat=false
prev=false
mod=false
obs=false
src_grd=false
bw=false
gettopo=false
ps="p_tdefnode.out.ps"
src_grd_file="dummy.grd"
topog_file="topog.grd"
topo_file="topo.grd"
cpt_file="temp.cpt"
projection="M9i"
tick="a.5f2nSWe"
v=" "
tif_tmp="topo.tif"
srtm_res="SRTM90"
plots=()
gmt_psvelo=()
gmtC_psvelo=()
gmtC_colors=()
strain=()
blkNames=()
nodeNumbers=()
faults=()
blkCoorNames=()
gmt_sites=()
gmtC_sites=()
gmtC_sites_colors=()
gmtZ_sites=()
gmtZ_sites_colortables=()
strainZ_cpt=()
strainZ=()
gmt_lines=()
gmtC_lines=()
gmtC_sites_lines=()
gmtZ_lines=()
gmtZ_sites_lines=()
gmt_labels=()
seismic=()
gmt_sitenames=()

if [ -f *.sum ] ; then
	MODL=`ls *.sum | awk '{print substr($1,1,4)}'`
	echo "$name: model name $MODL"
else
	echo "$name: Could not find model files."
fi

#Set global gmt defaults (Can be overridden in the defaults file)
gmt gmtset FORMAT_GEO_MAP ddd:mm:ssF
gmt gmtset PS_MEDIA 50ix200i #note we fix this at the end...
#gmt gmtset MAP_FRAME_TYPE inside

# Source overrides
if [ -f '.p_tdefnode.defaults' ]
then
	echo "$name: Reading in defaults file..."
	source .p_tdefnode.defaults
fi

# Process command line arguments
while [ $# -gt 0 ]; do
	case $1 in
		--rbuf|--bufferR)
			if [ -z ${2+x} ] || [ "${2:0:1}" = "-" ] ; then echo "$name: $1 requires argument" ; exit 1 ; fi
			rbuf=$2
			shift
			;;
		-o|--out)
			if [ -z ${2+x} ] || [ "${2:0:1}" = "-" ] ; then echo "$name: $1 requires argument" ; exit 1 ; fi
			ps=$2
			if [ ${ps:(-2)} != "ps" ] ; then ps="$ps.ps" ; fi
			shift
			;;
		-h|--help)
			usage
			;;
		-R|--range)
			#process
			range="$2"
			shift
			;;
		--rangeB)
			if [ -z ${2+x} ] || [ "${2:0:1}" = "-" ] ; then echo "$name: $1 requires argument" ; exit 1 ; fi
			if grep --quiet $2 ${MODL}_blk.gmt ; then
				lon_max=`gmt gmtconvert ${MODL}_blk.gmt -S$2 | awk '{if(NR>1){print $1}}' | sort -n | tail -1`
				lon_min=`gmt gmtconvert ${MODL}_blk.gmt -S$2 | awk '{if(NR>1){print $1}}' | sort -n | head -1`
				lat_max=`gmt gmtconvert ${MODL}_blk.gmt -S$2 | awk '{if(NR>1){print $2}}' | sort -n | tail -1`
				lat_min=`gmt gmtconvert ${MODL}_blk.gmt -S$2 | awk '{if(NR>1){print $2}}' | sort -n | head -1`
				lon_max=$(echo $lon_max + $rbuf | bc)
				lon_min=$(echo $lon_min - $rbuf | bc)
				lat_max=$(echo $lat_max + $rbuf | bc)
				lat_min=$(echo $lat_min - $rbuf | bc)
				range="$lon_min/$lon_max/$lat_min/$lat_max"
				echo "Setting range from ${MODL}_blk.gmt for block $2 to $range"
				shift
			else
				echo "Block $2 not found in ${MODL}, ignoring --rangeB $2 option..."
				shift
			fi
			;;
		--rangeM)
			if [ -f  ${MODL}_blk.gmt ] ; then
				lon_max=`awk '!/^>/ {print $1}' ${MODL}_blk.gmt | sort -n | tail -1`
				lon_min=`awk '!/^>/ {print $1}' ${MODL}_blk.gmt | sort -n | head -1`
				lat_max=`awk '!/^>/ {print $2}' ${MODL}_blk.gmt | sort -n | tail -1`
				lat_min=`awk '!/^>/ {print $2}' ${MODL}_blk.gmt | sort -n | head -1`
				lon_max=$(echo $lon_max + $rbuf | bc)
				lon_min=$(echo $lon_min - $rbuf | bc)
				lat_max=$(echo $lat_max + $rbuf | bc)
				lat_min=$(echo $lat_min - $rbuf | bc)
				range="$lon_min/$lon_max/$lat_min/$lat_max"
				echo "Setting range from ${MODL}_blk.gmt to $range"
			else
				echo "Block model ${MODL}_blk.gmt not found, ignoring --rangeM option..."
			fi
			;;
		--rangeF)
			if [ -z ${2+x} ] || [ "${2:0:1}" = "-" ] ; then echo "$name: $1 requires argument" ; exit 1 ; fi
			if [ -f  ${MODL}_flt_atr.gmt ] ; then
				lon_max=`awk '/^>/ {print $3,$11}' ${MODL}_flt_atr.gmt | grep "^$2" | awk '{print $2}' | sort -n | tail -1`
				lon_min=`awk '/^>/ {print $3,$11}' ${MODL}_flt_atr.gmt | grep "^$2" | awk '{print $2}' | sort -n | head -1`
				lat_max=`awk '/^>/ {print $3,$12}' ${MODL}_flt_atr.gmt | grep "^$2" | awk '{print $2}' | sort -n | tail -1`
				lat_min=`awk '/^>/ {print $3,$12}' ${MODL}_flt_atr.gmt | grep "^$2" | awk '{print $2}' | sort -n | head -1`
				lon_max=$(echo $lon_max + $rbuf | bc)
				lon_min=$(echo $lon_min - $rbuf | bc)
				lat_max=$(echo $lat_max + $rbuf | bc)
				lat_min=$(echo $lat_min - $rbuf | bc)
				range="$lon_min/$lon_max/$lat_min/$lat_max"
				echo "Setting range from ${MODL}_flt_atr.gmt for fault $2 to $range"
				shift
			else
				echo "Block model ${MODL}_flt_atr.gmt not found, ignoring --faultM $2 option..."
				shift
			fi
			;;
		--rangeS)
			if [ -z ${2+x} ] || [ "${2:0:1}" = "-" ] ; then echo "$name: $1 requires argument" ; exit 1 ; fi
			if [ ! -f $2 ]; then
				echo "$name: Supplied file argument $2 does not exist or path is set incorrectly"
				exit 1
			fi
			lon_max=`awk '{print $1}' $2 | sort -n | tail -1`
			lon_min=`awk '{print $1}' $2 | sort -n | head -1`
			lat_max=`awk '{print $2}' $2 | sort -n | tail -1`
			lat_min=`awk '{print $2}' $2 | sort -n | head -1`
			lon_max=$(echo $lon_max + $rbuf | bc)
			lon_min=$(echo $lon_min - $rbuf | bc)
			lat_max=$(echo $lat_max + $rbuf | bc)
			lat_min=$(echo $lat_min - $rbuf | bc)
			range="$lon_min/$lon_max/$lat_min/$lat_max"
			echo "Setting range from $2 to $range"
			shift
			;;
		-v|--verbose|-V)
			v="-V"
			;;
		--blk)
			plots+=("blk")
			;;
		--blkn)
			plots+=("blkn")
			;;
		--blkN)
			if [ -z ${2+x} ] || [ "${2:0:1}" = "-" ] ; then echo "$name: $1 requires argument" ; exit 1 ; fi
			if grep --quiet $2 ${MODL}_blk.gmt ; then
				plots+=("blkN")
				blkNames+=("$2")
				shift
			else
				echo "Block $2 not found in ${MODL}, ignoring --blkN $2 option..."
				shift
			fi
			;;
		--blkCoor)
			if [ -z ${2+x} ] || [ "${2:0:1}" = "-" ] ; then echo "$name: $1 requires argument" ; exit 1 ; fi
			plots+=("blkCoor")
			blkCoorNames+=("$2")
			shift
			;;
		--printB)
			echo "Printing block names used in model and exiting..."
			if [ -f  ${MODL}_blk.gmt ] ; then
				awk '/^>/ {print $0}' ${MODL}_blk.gmt
			else
				echo "Could not find ${MODL}_blk.gmt"
			fi
			exit 1
			;;
		--printF)
			echo "Printing fault numbers used in model and exiting..."
			if [ -f  ${MODL}.faults ] ; then
				awk '{if(NR>1){print $1,$2}}' ${MODL}.faults 
			else
				echo "Could not find ${MODL}.faults"
			fi
			exit 1
			;;
		--obs)
			plots+=("obs")
			;;
		--mod)
			plots+=("mod")
			;;
		--res)
			plots+=("res")
			;;
		--topo)
			topo=true
			;;
		--sites)
			plots+=("sites")
			;;
		--sta)
			plots+=("sta")
			;;
		--nodes)
			plots+=("nodes")
			;;
		--strain)
			if [ -z ${2+x} ] || [ "${2:0:1}" = "-" ] ; then echo "$name: $1 requires two arguments" ; exit 1 ; fi
			if [ ! -f $2 ]; then
				echo "$name: Supplied file argument $2 does not exist or path is set incorrectly"
				exit 1
			fi
			strain+=("$2")
			plots+=("strain")
			shift
			;;
		--strainZ)
			if [ -z ${2+x} ] || [ "${2:0:1}" = "-" ] ; then echo "$name: $1 requires two arguments" ; exit 1 ; fi
			if [ -z ${3+x} ] || [ "${3:0:1}" = "-" ] ; then echo "$name: $1 requires two arguments" ; exit 1 ; fi
			if [ ! -f $2 ]; then
				echo "$name: Supplied file argument $2 does not exist or path is set incorrectly"
				exit 1
			fi
			if [ ! -f $3 ]; then
				echo "$name: Supplied file argument $3 does not exist or path is set incorrectly"
				exit 1
			fi
			strainZ+=("$2")
			strainZ_cpt+=("$3")
			shift
			shift
			plots+=("strainZ")
			;;
		--bw)
			bw=true
			;;
		--gmt_sites)
			if [ -z ${2+x} ] || [ "${2:0:1}" = "-" ] ; then echo "$name: $1 requires argument" ; exit 1 ; fi
			gmt_sites+=("$2")
			if [ ! -f $2 ]; then
				echo "$name: Supplied file argument $2 does not exist or path is set incorrectly"
				exit 1
			fi
			shift
			plots+=("gmt_sites")
			;;
		--gmt_sitenames)
			if [ -z ${2+x} ] || [ "${2:0:1}" = "-" ] ; then echo "$name: $1 requires argument" ; exit 1 ; fi
			gmt_sitenames+=("$2")
			if [ ! -f $2 ]; then
				echo "$name: Supplied file argument $2 does not exist or path is set incorrectly"
				exit 1
			fi
			shift
			plots+=("gmt_sitenames")
			;;
		--seismic)
			if [ -z ${2+x} ] || [ "${2:0:1}" = "-" ] ; then echo "$name: $1 requires argument" ; exit 1 ; fi
			seismic+=("$2")
			if [ ! -f $2 ]; then
				echo "$name: Supplied file argument $2 does not exist or path is set incorrectly"
				exit 1
			fi
			shift
			plots+=("seismic")
			;;
		--gmtC_sites)
			if [ -z ${2+x} ] || [ "${2:0:1}" = "-" ] ; then echo "$name: $1 requires two arguments" ; exit 1 ; fi
			if [ -z ${3+x} ] || [ "${3:0:1}" = "-" ] ; then echo "$name: $1 requires two arguments" ; exit 1 ; fi
			gmtC_sites+=("$2")
			gmtC_sites_colors+=("$3")
			if [ ! -f $2 ]; then
				echo "$name: Supplied file argument $2 does not exist or path is set incorrectly"
				exit 1
			fi
			shift
			shift
			plots+=("gmtC_sites")
			;;
		--gmtZ_sites)
			if [ -z ${2+x} ] || [ "${2:0:1}" = "-" ] ; then echo "$name: $1 requires two arguments" ; exit 1 ; fi
			if [ -z ${3+x} ] || [ "${3:0:1}" = "-" ] ; then echo "$name: $1 requires two arguments" ; exit 1 ; fi
			gmtZ_sites+=("$2")
			gmtZ_sites_colortables+=("$3")
			if [ ! -f $2 ]; then
				echo "$name: Supplied file argument $2 does not exist or path is set incorrectly"
				exit 1
			fi
			if [ ! -f $3 ]; then
				echo "$name: Supplied file argument $3 does not exist or path is set incorrectly"
				exit 1
			fi
			shift
			shift
			plots+=("gmtZ_sites")
			;;
		--gmt_lines)
			if [ -z ${2+x} ] || [ "${2:0:1}" = "-" ] ; then echo "$name: $1 requires argument" ; exit 1 ; fi
			gmt_lines+=("$2")
			if [ ! -f $2 ]; then
				echo "$name: Supplied file argument $2 does not exist or path is set incorrectly"
				exit 1
			fi
			shift
			plots+=("gmt_lines")
			;;
		--gmtC_lines)
			if [ -z ${2+x} ] || [ "${2:0:1}" = "-" ] ; then echo "$name: $1 requires two arguments" ; exit 1 ; fi
			if [ -z ${3+x} ] || [ "${3:0:1}" = "-" ] ; then echo "$name: $1 requires two arguments" ; exit 1 ; fi
			gmtC_lines+=("$2")
			gmtC_lines_colors+=("$3")
			if [ ! -f $2 ]; then
				echo "$name: Supplied file argument $2 does not exist or path is set incorrectly"
				exit 1
			fi
			shift
			shift
			plots+=("gmtC_lines")
			;;
		--gmt_labels)
			if [ -z ${2+x} ] || [ "${2:0:1}" = "-" ] ; then echo "$name: $1 requires argument" ; exit 1 ; fi
			gmt_labels+=("$2")
			if [ ! -f $2 ]; then
				echo "$name: Supplied file argument $2 does not exist or path is set incorrectly"
				exit 1
			fi
			shift
			plots+=("gmt_labels")
			;;
		--gmtZ_lines)
			if [ -z ${2+x} ] || [ "${2:0:1}" = "-" ] ; then echo "$name: $1 requires two arguments" ; exit 1 ; fi
			if [ -z ${3+x} ] || [ "${3:0:1}" = "-" ] ; then echo "$name: $1 requires two arguments" ; exit 1 ; fi
			gmtZ_lines+=("$2")
			gmtZ_lines_colortables+=("$3")
			if [ ! -f $2 ]; then
				echo "$name: Supplied file argument $2 does not exist or path is set incorrectly"
				exit 1
			fi
			if [ ! -f $3 ]; then
				echo "$name: Supplied file argument $3 does not exist or path is set incorrectly"
				exit 1
			fi
			shift
			shift
			plots+=("gmtZ_lines")
			;;
		--gmt_velo)
			if [ -z ${2+x} ] || [ "${2:0:1}" = "-" ] ; then echo "$name: $1 requires argument" ; exit 1 ; fi
			gmt_psvelo+=("$2")
			if [ ! -f $2 ]; then
				echo "$name: Supplied file argument $2 does not exist or path is set incorrectly"
				exit 1
			fi
			shift
			plots+=("gmt_velo")
			;;
		--gmtC_velo)
			if [ -z ${2+x} ] || [ "${2:0:1}" = "-" ] ; then echo "$name: $1 requires two arguments" ; exit 1 ; fi
			if [ -z ${3+x} ] || [ "${3:0:1}" = "-" ] ; then echo "$name: $1 requires two arguments" ; exit 1 ; fi
			gmtC_psvelo+=("$2")
			gmtC_colors+=("$3")
			if [ ! -f $2 ]; then
				echo "$name: Supplied file argument $2 does not exist or path is set incorrectly"
				exit 1
			fi
			shift
			shift
			plots+=("gmtC_velo")
			;;
		--faults|--flt)
			plots+=("faults")
			;;
		--fault)
			if [ -z ${2+x} ] || [ "${2:0:1}" = "-" ] ; then echo "$name: $1 requires argument" ; exit 1 ; fi
			if awk '{print $2}' ${MODL}.nod | grep --quiet $2 ; then
				plots+=("fault")
				faults+=("$2")
				shift
			else
				echo "Fault $2 not found in ${MODL}, ignoring --fault $2 option..."
				shift
			fi
			;;
		--nodeN)
			if [ -z ${2+x} ] || [ "${2:0:1}" = "-" ] ; then echo "$name: $1 requires argument" ; exit 1 ; fi
			if awk '{print $2}' ${MODL}.nod | grep --quiet $2 ; then
				plots+=("nodeN")
				nodeNumbers+=("$2")
				shift
			else
				echo "Nodes for $2 not found in ${MODL}, ignoring --nodeN $2 option..."
				shift
			fi
			;;
		--topof)
			if [ -z ${2+x} ] || [ "${2:0:1}" = "-" ] ; then echo "$name: $1 requires argument" ; exit 1 ; fi
			topo_file="$2"
			shift
			if [ ! -f $topo_file ]; then
				echo "$name: Supplied file argument $topo_file does not exist or path is set incorrectly"
				exit 1
			fi
			;;
		--topog)
			if [ -z ${2+x} ] || [ "${2:0:1}" = "-" ] ; then echo "$name: $1 requires argument" ; exit 1 ; fi
			topog_file="$2"
			shift
			if [ ! -f $topog_file ]; then
				echo "$name: Supplied file argument $topog_file does not exist or path is set incorrectly"
				exit 1
			fi
			;;
		--topo_flat)
			topo_flat=true
			;;
		--topo_cpt)
			if [ -z ${2+x} ] || [ "${2:0:1}" = "-" ] ; then echo "$name: $1 requires argument" ; exit 1 ; fi
			cpt_file="$2"
			shift
			if [ ! -f $cpt_file ]; then
				echo "$name: Supplied file argument $cpt_file does not exist or path is set incorrectly"
				echo "$name: Will build default color table with GMT table globe"
				$cpt_file = "temp.cpt"
			fi
			;;
		--proj)
			$projection="$2"
			;;
		--tick)
			$tick="$2"
			;;
		--prev|--show)
			prev=true
			;;	
		--getTopo)
			gettopo=true
			topo=true
			;;
		--srtm30)
			srtm_res="SRTM30"
			;;
		*)
			echo "Unknown option $1 skipping ..."
			;;
	esac
	shift
done

#make sure required arguments are present, range is required from here on
if [ -z "$range" ]; then
	echo "$0: Range does not exist or not supplied in .p_tdefnode.defaults, use --range, --rangeB, --rangeM or --rangeF"
	exit 1
fi

#Draw base and add topography as needed.

#Get the topo of we are asked
if $gettopo ; then
	
	GET_URL=`echo $range | awk -F/ -v sr=$srtm_res '{printf "http://ot-data1.sdsc.edu:9090/otr/getdem?north=%4.3f&south=%4.3f&&east=%4.3f&west=%4.3f&demtype=%s",$4,$3,$2,$1,sr}'`
	echo $GET_URL
	wget -O $tif_tmp "$GET_URL"
	
	if [ ! -f $tif_tmp ] ; then
		echo "--getTopo failed...."
		exit 1
	fi
	
	echo "Converting GeoTIFF $tif_tmp to GMT $topo_file ..."
	gmt grdreformat ${tif_tmp} ${topo_file}=gd:netCDF $v
	
	# Use this is gdal is installed  
	#if [ `which gdal_translate` ] ; then 
	#		gdal_translate -of netCDF topo.tif $topo_file
	#else
	#	echo "gdal_translate does not exist or is not in path correctly."
		#exit 1
	#fi
fi

#Cut out the topography from a master data set if topo set, src_grd set and no topo file
if [ ! -f $src_grd_file ] && $src_grd ; then
	echo "$name: Could not find $src_grd_file"
	exit 1
fi

if [ ! -f $topo_file ] && $topo && $src_grd && [ -f $src_grd_file ]  ; then
	gmt grdcut $src_grd_file -G$topo_file -R$range $v
fi

if $topo ; then
	#check to see we have a topo file
	if [ ! -f $topo_file ]; then
		echo "$name: Supplied file argument $topo_file does not exist or path is set incorrectly"
		exit 1
	fi
fi

# Build a gradient file if needed - TODO prevent this if topo_flat
if [ ! -f $topog_file ] && $topo ; then
	gmt grdgradient $topo_file -A250 -G$topog_file -Nt $v
fi

# Build a cpt file if needed
if $topo && [ ! -f $cpt_file ] ; then
	gmt grd2cpt $topo_file -Cglobe -T= -Z $v > $cpt_file
fi

if $bw ; then
	gmt grd2cpt $topo_file -Cgray -T= -Z $v > $cpt_file
fi

if $topo ; then
	if $topo_flat ; then
		gmt grdimage $topo_file -R$range -B$tick -C$cpt_file -J$projection $v -K > $ps
	else
		gmt grdimage $topo_file -R$range -B$tick -C$cpt_file -J$projection -I$topog_file $v -K > $ps
	fi
	gmt pscoast -R$range -J$projection -B$tick -Slightblue -N1 -W1/thin,black,solid -W2/thin,black,solid $v -Df -O -K >> $ps
else
	gmt pscoast -R$range -J$projection -B$tick -Slightblue -N1 -W1/thin,black,solid -W2/thin,black,solid $v -Df -K > $ps
fi

#Plot the tdefnode plot requests in the order they are given
for plot in ${plots[@]} ; do
	case $plot in
		blk)
			gmt psxy ${MODL}_blk.gmt -L -R$range -J$projection -B$tick -Wfat,black,solid -K -O $v >> $ps
			gmt psxy ${MODL}_blk3.gmt -R$range -J$projection -Wfatter,orange,solid -K -O $v >> $ps
    		gmt psxy ${MODL}_blk3.gmt -R$range -J$projection -Wthickest,black,solid -K -O $v >> $ps
			;;
		blkn)
			awk ' { print $2, $3, $1 } ' ${MODL}_blocks.out | gmt pstext  -J$projection -R$range -O -K -F+f9p,Helvetica,red $v >> $ps
			;;
		blkN)
			gmt gmtconvert ${MODL}_blk.gmt -S${blkNames[0]} | gmt psxy -L -R$range -J$projection -B$tick -Wfat,black,solid -K -O $v >> $ps
			blkNames=("${blkNames[@]:1}")
			;;
		blkCoor)
			gmt gmtconvert ${MODL}_blk.gmt -S${blkCoorNames[0]} | awk '{print $1,$2,NR-1}' | gmt pstext -J$projection -R$range -O -K -F+f12p,Helvetica,red $v >> $ps
			blkCoorNames=("${blkCoorNames[@]:1}")
			;;
		obs)
			awk '{ if ($5==1 && $6==1) print $8, $9, $12, $17, 0, 0, 0, $1 }' $MODL.vsum |  gmt psvelo -J$projection -R$range  -Se1c/0.683/5 -Wthin,black,solid -Gblack -K -O $v >> $ps
			;;
		mod)
			awk '{ if ($5==1 && $6==1) print $8, $9, $13, $18, 0, 0, 0 }' $MODL.vsum |  gmt psvelo -J$projection -R$range  -Se1c/0.683/5 -Wthin,red,solid -Gred -K -O $v >> $ps
			;;
		res)
			awk '{ if ($5==1 && $6==1) print $8, $9, $14, $19, 0, 0, 0, $1 }' $MODL.vsum |  gmt psvelo -J$projection -R$range  -Se1c/0.683/5 -Wthin,red,solid -Gred -K -O $v >> $ps
			;;
		sites)
			awk '{print $8,$9}' ${MODL}.vsum | gmt psxy -Sc0.2 -R -G255/20/0 -W1,255/20/0 -J$projection -K -O $v >> $ps
			;;
		sta)
			awk '{print $8,$9,"8 0 0 CM",$1}' ${MODL}.vsum | gmt pstext -D0.2 -O -K -J$projection -R$range -W1,255/20/0 -C0/0 $v  >> $ps
			;;
		nodes)
			gmt psxy ${MODL}_blk.gmt -L -R$range -J$projection -B$tick -Wthicker,black,solid -K -O $v >> $ps
			awk '{if ($4==1) print $7, $8, $2}' $MODL.nod | gmt pstext -J$projection -R$range -O -K -F+f12p,Helvetica,red $v >> $ps
			;;
		faults)
			if [ ! -f "f962.cpt" ] ; then
				#Build a color table from 0 or max depth based on red2green
				max_depth=`awk '{if($1==">") print $13}' ${MODL}_flt_atr.gmt | sort -n | head -1`
				gmt makecpt -D -Z -T$max_depth/0 -Cpolar $v > f962.cpt
			fi
			#Plot fault rectangles colored by depth
			awk '{ if ($1 ==">") printf "%s %s%f\n",$1,$2,$13; else print $1,$2 }' ${MODL}_flt_atr.gmt | gmt psxy -R$range -J$projection -B$tick -L -Cf962.cpt -O -K $v >> $ps
			;;
		fault)
			if [ ! -f "f962.cpt" ] ; then
				#Build a color table from 0 or max depth based on red2green
				echo "Making color table"
				max_depth=`awk '{if($1==">") print $13}' ${MODL}_flt_atr.gmt | sort -n | head -1`
				gmt makecpt -D -Z -I -T$max_depth/0 -Cpolar $v > f962.cpt
			fi
			#Plot fault rectangles colored by depth
			number=`echo ${faults[0]} | awk '{printf "%03d",$1}'`
			if [ -e ${MODL}_flt_${number}_atr.gmt ] ; then
				awk '{ if ($1 ==">") printf "%s %s%f\n",$1,$2,$13; else print $1,$2 }' ${MODL}_flt_${number}_atr.gmt | gmt psxy -R$range -J$projection -B$tick -L -Cf962.cpt -O -K $v >> $ps
			else
				echo "Could not find ${MODL}_flt_${number}_atr.gmt , can not plot fault $number"
			fi
			faults=("${faults[@]:1}")
			;;
		nodeN)
			awk -v n="${nodeNumbers[0]}" '{if ($4==1 && $2==n) print $7, $8, $2}' $MODL.nod | gmt pstext -J$projection -R$range -O -K -F+f7p,Helvetica,red $v >> $ps
			nodeNumbers=("${nodeNumbers[@]:1}")
			;;
		gmt_labels)
			awk '{print $1,$2}' ${gmt_labels[0]} | gmt psxy -Sc0.2 -R -G255/20/0 -W1,255/20/0 -J$projection -K -O $v >> $ps
			awk '{print $1,$2,"14 0 0 CM",$3}' ${gmt_labels[0]} | gmt pstext -D0.2 -O -K -J$projection -R$range  -C0/0 $v  >> $ps
			gmt_labels=("${gmt_labels[@]:1}") 
			;;
		gmt_sites)
			awk '{print $1,$2}' ${gmt_sites[0]} | gmt psxy -Sc0.2 -R -G255/20/0 -W1,255/20/0 -J$projection -K -O $v >> $ps
			gmt_sites=("${gmt_sites[@]:1}")
			;;
		gmt_sitenames)
			awk '{print $1,$2,"14 0 0 CM",$3}' ${gmt_sitenames[0]} | gmt pstext -D0.2 -O -K -J$projection -R$range  -C0/0 $v >> $ps
			gmt_sitenames=("${gmt_sitenames[@]:1}")
			;;
		sesimic)
			awk '{print $1,$2}' ${seismic[0]} | gmt psxy -Sp -R -G255/20/0 -W1,255/20/0 -J$projection -K -O $v >> $ps
			seismic=("${seismic[@]:1}")
			;;
		gmtC_sites)
			awk '{print $1,$2}' ${gmtC_sites[0]} | gmt psxy -Sc0.2 -R -G${gmtC_sites_colors[0]} -W1,${gmtC_sites_colors[0]} -J$projection -K -O $v >> $ps
			gmtC_sites=("${gmtC_sites[@]:1}")
			gmtC_sites_colors=("${gmtC_sites_colors[@]:1}")
			;;
		gmtZ_sites)
			awk '{print $1,$2,$3}' ${gmtZ_sites[0]} | gmt psxy -Sc0.2 -R -C${gmtZ_sites_colortables[0]} -J$projection -K -O $v >> $ps
			gmtZ_sites=("${gmtZ_sites[@]:1}")
			gmtZ_sites_colortables=("${gmtZ_sites_colortables[@]:1}")
			;;
		gmt_lines)
			awk '{print $1,$2}' ${gmt_lines[0]} | gmt psxy -R -W1,black -J$projection -K -O $v >> $ps
			gmt_sites=("${gmt_lines[@]:1}")
			;;
		gmtC_lines)
			awk '{print $1,$2}' ${gmtC_lines[0]} | gmt psxy -R -W1,${gmtC_lines_colors[0]} -J$projection -K -O $v >> $ps
			gmtC_lines=("${gmtC_lines[@]:1}")
			gmtC_lines_colors=("${gmtC_lines_colors[@]:1}")
			;;
		gmtZ_lines)
			awk '{print $1,$2,$3}' ${gmtZ_lines[0]} | gmt psxy -R -C${gmtZ_lines_colortables[0]} -J$projection -K -O $v >> $ps
			gmtZ_lines=("${gmtZ_lines[@]:1}")
			gmtZ_lines_colortables=("${gmtZ_lines_colortables[@]:1}")
			;;
		gmt_velo)
			gmt psvelo ${gmt_psvelo[0]} -J$projection -R$range  -Se0.1c/0.683/5 -Wthin,black,solid -Gblack -K -O $v >> $ps
			gmt_psvelo=("${gmt_psvelo[@]:1}")
			;;
		gmtC_velo)
			gmt psvelo ${gmtC_psvelo[0]} -J$projection -R$range  -Se0.1c/0.683/5 -Wthin,${gmtC_colors[0]},solid -G${gmtC_colors[0]} -K -O $v >> $ps
			gmtC_psvelo=("${gmtC_psvelo[@]:1}")
			gmtC_colors=("${gmtC_colors[@]:1}")
			;;
		strain)
			#gmt makecpt -Z -Cpolar -D -T-.02/.02 > shear.cpt
			gmt grd2cpt ${strain[0]} -Cpolar -T= -Z > shear.cpt
			gmt grdimage ${strain[0]} -Q -t40 -Q -J$projection -R$range -Cshear.cpt -K -O $v >> $ps
			#gmt grdcontour ${strain[0]} -C.05 -J$projection -R$range -K -O $v -A.05 -S  >> $ps
			#awk '{print $1,$2}'  everest.txt | gmt psxy -Sc0.2 -R -G255/20/0 -W1,255/20/0 -J$projection -K -O -V >> $ps
			#awk '{print $1,$2,"14 0 0 CM",$3}' everest.txt | pstext -D0.2 -O -K -J$projection -R$range  -C0/0 $v  >> $ps
			strain=("${strain[@]:1}")
			;;
		strainZ)
			gmt grdimage ${strainZ[0]} -t40 -Q -J$projection -R$range -C${strainZ_cpt[0]} -K -O $v >> $ps
			strainZ=("${strainZ[@]:1}")
			strainZ_cpt=("${strainZ_cpt[@]:1}")
			;;
	esac
done

# this also properly closes the postscript...
echo ".9 .5 1.0 0 .1 .11 0 10 mm/yr" | gmt psvelo -JX5c -R0/5/0/5 -Se1c/0.683/5 -Wthick,black,solid -K -O >> $ps
echo "Image produced using $name:Mencin/Vernant 2015 Version:$version " `date` | gmt pstext -R0/8/0/1 -JX8i -Xa-.8i -Ya-.8i -F+f7p,Helvetica,black+cBL -O >> $ps

echo "Writing... ${ps%.*}.pdf"
#Change the ps file to a PDF, this is more compatible and allows to adjust the bounding box
gmt ps2raster -A1i -P -Tf $ps
#gmt ps2raster -A+r -P -Tj $ps

rm $ps

#Clean up temp files if they were used
if [ -e "temp.cpt" ] ; then rm temp.cpt ; fi
#if [ -e "topo.grd" ] ; then rm topo.grd ; fi
if [ -e "topog.grd" ] ; then rm topog.grd ; fi
if [ -e "gmt.conf" ] ; then rm gmt.conf ; fi
if [ -e "gmt.history" ] ; then rm gmt.history ; fi
if [ -e "f962.cpt" ] ; then rm f962.cpt ; fi
if [ -e "shear.cpt" ] ; then rm shear.cpt ; fi

if $prev ; then
	if [ `uname` = "Darwin" ] ; then
		open -a preview ${ps%.*}.pdf
	else
		if [ `which gs` ] ; then
			gs ${ps%.*}.pdf
		else
			echo "--prev can't find gs in path"
		fi
	fi
fi

echo "Exiting... $name"
