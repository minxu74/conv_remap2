#!/usr/bin/env bash 


# Min Xu and Forrest Hoffman
# ORNL

# Contact: minxu@climatemodeling.org


#nco functions copy from nco users' guide
      export NCO_PATH_OVERRIDE='No' 

function ncdmnlst { ncks --cdl -m ${1} | cut -d ':' -f 1 | cut -d '=' -s -f 1 ; }

#get binary directory of nco
ncotest=$(which ncremap 2>&1)
if [ $? = 1 ]; then
   echo ncremap and other NCO tools are needed for running $(basename $0)
   exit -1
fi



esmftes=$(which ESMF_RegridWeightGen 2>&1)

if [ $? = 1 ]; then
   echo ESMF_RegridWeightGen is required for runing $(basename $0)
   exit -1
fi

ncobdir=$(cd "$(dirname $(which ncremap))" && pwd)

if [ -d ${ncobdir} ];  
then
   echo "find the nco toolkit in $ncobdir"
else
   echo ncremap and other NCO tools are needed in $(basename $0)
   exit -1
fi

#ncaptest=$(which ncap 2>&1)
#if [ $? = 0 ]; then
#   ncapbin=$ncobdir/ncap
#else
#   ncaptest=$(which ncap2 2>&1)
#   if [ $? = 0 ]; then
#      ncapbin=$ncobdir/ncap2
#   fi
#fi

ncapbin=$ncobdir/ncap2

if [ -z ${ncapbin+x} ]; then
   echo ncap2 and ncap are needed in $(basename $0)
fi

echo $ncapbin


#mxu check ncremap if sgs options
out_ncremap="$($ncobdir/ncremap)"

if [[ $out_ncremap == *"sgs"* ]]; then
   useold=0
else
   useold=1
fi

# source and targe grid description in SCRIP format
s="SCRIPgrid_ne30np4_nomask_c101123.nc"
d="SCRIPgrid_fv09_nomask_c101123.nc"


function print_usage {
   printf "\n"
   echo -e "\033[1mUsage:\033[0m $0 -i src_dat -o dst_dat -s src_grd -d dst_grd "
   echo "Command-line options"
   echo "      -i src_dat	the data file or directory that contains data files (default: *clm2*.nc) to be remapped"
   echo "      -o dst_dat	the directory in which the remapped data will be saved"
   echo "      -s src_grd	the SCRIP format grid description for src_dat"
   echo "      -d dst_grd	the SCRIP format grid description for dst_dat"
   echo "      -k keyword	optional (default is clm2), when src_dat is directory, only data with the pattern "*keyword*.nc" in their name will be remapped"
   echo " "
}

# command-line parsing
while getopts vh:i:o:s:d:k: OPT; do
   case ${OPT} in
      s) src_grd=${OPTARG}    ;; # source grid description in SCRIP format
      d) dst_grd=${OPTARG}    ;; # destination grid description in SCRIP format
      i) src_dat=${OPTARG}    ;; # source grid data or data directory
      o) dst_dat=${OPTARG}    ;; # destination grid directory
      k) keyword=${OPTARG}    ;; # keyword used to select input files under src_grd
      h) 
         print_usage 
         exit -1 ;; # help
      v) set -x               ;; # turn on bash debugging
      \?)                        # unknown options
         printf "\n Error: unknown options"
         print_usage 
         exit -1 ;;
   esac
done

if [ $OPTIND -eq 1 ]; then
   print_usage
   exit -1
fi

s=${src_grd}
d=${dst_grd}

if [[ -d ${src_dat} ]]; then
   src_dir=${src_dat}
   unset src_fil
elif [[ -e ${src_dat} ]]; then 
   src_fil=${src_dat}
else
   echo "src_dat: ${src_dat} file or directory not exist"
   exit -2
fi

if [[ -d ${dst_dat} ]]; then
   dst_dir=${dst_dat}
else
   echo "dst_dir: $dst_dat is not exist, reset to current directory"
   dst_dir="./"
fi

if [[ ! -e $s ]]; then
    echo "source grid description in SCRIP format is needed"
    exit -1
fi

if [[ ! -e $d ]]; then
    echo "destination grid description in SCRIP format is needed"
    exit -1
fi

if [[ -z ${keyword+x} ]]; then
    kw="clm2"
else
    kw=$keyword
fi

echo "---------------------------------------------------------"
echo "Summary: "
echo "src_dat: $src_dir$srcfil" 
echo "dst_dat: $dst_dir"
echo "src_grd: $s "
echo "dst_grd: $d "
echo "search filename pattern: $kw"
echo "---------------------------------------------------------"

# test if the src_fil has been defined.

if [[ -z ${src_fil+x} ]]; then
    echo "Nonexisit input file, so search all nc files with $kw in their filenames under the ${src_dir}"
    Infiles=(${src_dir}/*$kw*.nc)
else
    echo ${src_fil}
    Infiles=(${src_fil})
fi

shopt -s nullglob

if [[ ${#Infiles[@]} == 1 && $Infiles[0] == *"*"* ]]; then
    echo "cannot find files with their filename containing  $kw"
    exit -1
fi

# --- core part ---
i=0

for f in "${Infiles[@]}"
do
   echo "remapping $f"

   i=$((i + 1))

   # sm -- source SCRIP grid file containing the land area and mask derived from data file
   # dm -- destination SCRIP grid file containing the land area and mask derived from data file
   ts=c`date +"%y%m%d"`
   sm=`echo "$s" | sed 's/nomask/mask_landarea_wgt/'`   # source SCRIP grid file using land area and land mask
   dm=`echo "$d" | sed 's/nomask/mask_landarea_wgt/'`   
   sm=`echo $sm | sed "s/c[0-9]\+/\$ts/"`
   dm=`echo $dm | sed "s/c[0-9]\+/\$ts/"`
   fo=interp_$(basename $f)

   if [ "$i" = "1" ]; then
      echo $i
   

# 
      #extract landfrac from data, we do not use the area variable in the data file, because 
      #its values are _FillValue over ocean. Instead we use the area variable from the source 
      #SCRIP grid file. They should be exactly same, except the units
      $ncobdir/ncks -O -v landfrac $f a.nc


      #-dimenions=`ncdmnlst $f`

      #-if [[ $dimension == *"lndgrid"* ]];
      #-   $ncobdir/ncrename -O -d lndgrid,grid_size a.nc
      #-else
      #-   $ncobdir/ncrename -O -d lndgrid,grid_size a.nc

      #-fi
      #-exit



   #extract lat/lon and area from source SCRIP grid file
cat <<EOF >./tmp1.nco
  lat=grid_center_lat;
  lon=grid_center_lon;
  area=grid_area;
EOF
      #the area is gridcell area
      $ncapbin -O -v -S tmp1.nco $s -o b.nc
      /bin/rm -f tmp1.nco
      
      #combine the area and landfrac variables
      $ncobdir/ncks -A a.nc b.nc
      /bin/rm -f a.nc
      
      #remove the _FillValue and missing_value of landfrac. It is true that landfrac=0 over ocean.
      $ncobdir/ncatted -a    _FillValue,landfrac,d,, b.nc
      $ncobdir/ncatted -a missing_value,landfrac,d,, b.nc


      #test
      #$ncobdir/ncks -O -v landfrac,area,
cat <<EOF >./tmp2.nco
   where(landfrac > 1) landfrac=0.0;
   grid_area=area;
   grid_area=landfrac;
   grid_area=grid_area*area;
   grid_imask=int(grid_area)*0;
   where(grid_area > 0) grid_imask=1;
   elsewhere            grid_imask=0;
EOF
   
      #get grid_area and grid_imask for source SCRIP grid by the land area
      $ncapbin -O -S tmp2.nco b.nc -o g_src.nc


      /bin/rm -f b.nc
      /bin/rm -f tmp2.nco
      
      #put the grid_area and grid_imask data into the source SCRIP grid file for ncremap
      $ncobdir/ncks -O -x -v grid_area,grid_imask $s $sm
      $ncobdir/ncks -A -v grid_area,grid_imask g_src.nc $sm
      
      #change the units and long_name for grid_area
      $ncobdir/ncatted -a units,grid_area,o,c,'radians^2' $sm 
      $ncobdir/ncatted -a long_name,grid_area,o,c,'area weights' $sm 
      $ncobdir/ncatted -a units,grid_imask,o,c,'unitless' $sm

      $ncobdir/ncks -O -v landfrac g_src.nc b.nc
      /bin/mv -f b.nc g_src.nc

      #ncremap can only recognize the dimension name as lndgrid etc.
      $ncobdir/ncrename -O -d grid_size,lndgrid g_src.nc
      
      #remap the landfrac data from src to dst grid using the entire grid area and without any masks. 
      $ncobdir/ncremap -i g_src.nc -s $s -g $d -a conserve -o g_dst.nc


      /bin/rm -f g_src.nc

      $ncobdir/ncks -h -A $d g_dst.nc

      
      #landfrac is conservtive now, get the grid_area, landmask in the destination SCRIP grid
cat <<EOF >./tmp3.nco
   grid_area=grid_center_lat*0.0;
   grid_lndf=grid_center_lat*0.0;
   grid_area=area;
   grid_lndf=landfrac;
   grid_area=grid_area*grid_lndf;
   grid_imask=int(grid_center_lat)*0;
   where(grid_area>0) grid_imask=1;
   elsewhere          grid_imask=0;
EOF
      $ncapbin -O -S tmp3.nco g_dst.nc z.nc
      /bin/rm -f tmp3.nco
      $ncobdir/ncks -O -v grid_area,grid_imask z.nc y.nc
      $ncobdir/ncatted -a units,grid_area,o,c,'radians^2' y.nc
      $ncobdir/ncatted -a long_name,grid_area,o,c,'area weights' y.nc

      #put the grid_area and grid_imask data into the source SCRIP grid file for ncremap
      $ncobdir/ncks -O -x -v grid_area,grid_imask $d $dm
      $ncobdir/ncks -A -v grid_area,grid_imask y.nc $dm

      echo $dm, 'xxxx'

      /bin/rm -f y.nc
      
#-cat <<EOF >./tmp4.nco
#-    grid_area=grid_center_lat*0.0; 
#-EOF
#-      $ncapbin -O -S tmp4.nco $d $dm
#-
#-      /bin/rm -f tmp4.nco
#-
#-      # I used the ncl to reshape the dimensions of the grid_area and grid_imask variables, 
#-      # I do not know how to do it using NCO.
#-      /bin/rm -f tmp1.ncl
#-cat <<EOF >./tmp1.ncl
#-begin
#-   f = addfile(sgrd, "r")
#-   g = addfile(dgrd, "w")
#-   dims = dimsizes(f->grid_area)
#-   size = 1
#-   do i = 0, dimsizes(dims) - 1
#-      size = size * dims(i)
#-   end do
#-   g->grid_area = reshape(f->grid_area,size)
#-   g->grid_imask = where(reshape(f->grid_area,size) .gt. 0, 1, 0)
#-   delete(f)
#-   delete(g)
#-end
#-EOF
#-      ncl tmp1.ncl sgrd=\"y.nc\" dgrd=\"$dm\"
#-      /bin/rm -f y.nc


   fi   # finish generating the masked destination grid description file

   #do ncremap again, but using land area instead of grid area


   if [[ $useold == 1 ]]; then 
      export NCO_PATH_OVERRIDE='No' 
      $ncobdir/ncrename -O -d .gridcell,gridxxxx $f  -o xxx.nc
       if [ "$i" = "1" ]; then
          $ncobdir/ncremap -i xxx.nc -s $sm -g $dm -a conserve -E '--user_areas -i' -o test.nc -m map.nc
       else
          $ncobdir/ncremap -i xxx.nc -o test.nc -m map.nc
       fi
   else
      # make the new nco version work
      # turn off path hardcoded in ncremap, especially the 'modele load ncl'
      # will load ncl/6.1.0 and ESMF_RegridWeightGen's version is less than 6.3.0
      export NCO_PATH_OVERRIDE='No' 
      $ncobdir/ncrename -O -d .gridcell,gridxxxx $f  -o xxx.nc
       if [ "$i" = "1" ]; then
          $ncobdir/ncremap -i xxx.nc -s $sm -g $dm -a conserve -W '--user_areas -i' -o test.nc -m map.nc
       else
          $ncobdir/ncremap -i xxx.nc -o test.nc -m map.nc
       fi
       /bin/rm -f xxx.nc
       echo 'xxxx'
   fi

   $ncobdir/ncks -O -x -v area,landmask,landfrac test.nc $dst_dir/$fo
   $ncobdir/ncks -O -v area,landmask,landfrac z.nc w.nc
   $ncobdir/ncks -A w.nc $dst_dir/$fo 
   $ncobdir/ncatted -a long_name,landmask,o,c'land mask (0-ocean,1-land)' $dst_dir/$fo

   /bin/rm -f w.nc #z.nc
done


#clean up
/bin/rm -f test.nc
/bin/rm -f z.nc
/bin/rm -f g_dst.nc
exit 0
