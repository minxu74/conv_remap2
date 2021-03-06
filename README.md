# Conservatively Remapping the outputs of land models

## Introduction

This bash script utilizes the NCO toolkit (ncks, ncap2, ncrename, and ncremap etc.) to conservatively remap the land model outputs 
from one grid to others. In order to run the script, the NCO toolkit and NCL are needed, as well as the non-masked source and destination 
grid description files in SCRIP format (Normally can be found in CESM/ACME input directory or can be generated by ncks or NCL).

***Attn:*** the version of the ESMF tool "ESMF_RegridWeightGen" (ERWG) should be no less than 6.3.0 otherwise the option "--user_areas" is *not* 
available.  

The major steps of the script are:

1. generate the masked source grid SCRIP desciption file (src_grd). The "grid_area" in the src_grd is the gridcell land area instead of 
gridcell entire area in default and the "grid_imask" is set by the landfrac variable read from input files (1 when landfrac > 0; 0 otherwise).  

2. use *ncremap* to remap land area in the source grid file to the destination grid. The remapped land area is used to set the "grid_area" and 
"grid_imask" in the destination grid description file (dst_grd).

3. use *ncremap* with the option of "--user_areas" for ERWG and src_grd and dst_grd to conservatively remap input files.


The reasons that we cannot use ncremap and non-masked source/destination grid files directly are

1. ncremap uses ERWG to compute the mapping coefficients and ERWG will make conservative remappings by using the "grid_area" in the source grid file
that is generally gridcell entire area and the calculted "grids_area" for destination grid. The conservation is maded on the gridcell area, not land 
area that we expect.

2. the land model outputs normally mask out the ocean part and were set the "\_FillValue", *ncreamp* can be aware of the masked varaibles, during 
remapping, however, some destination gridcells are not fully covered by valid source gridcells. The valid (non \_FillValue) source variables get 
spread-out (and reduced) over a larger destination area. It will cause some strange values (very small values) along the coastlines.


## Basic usage:

1. conv_reamp -h  # show the help information

2. conv_remap -v  # turn on the bash debug mode (set -x)

3. conv_remap -i ./conv_remap2.sh -i I_acme_enso_camse_clm45bgc_ne30_2000_edison 
                     -s SCRIPgrid_ne30np4_nomask_c101123.nc -d SCRIPgrid_fv09_c110307.nc # remap all files "*clm2*.nc" in the
                     directory "I_acme_enso_camse_clm45bgc_ne30_2000_edison" from ne30np4 grid to fv09 grid.

## Reference:

1. NCO user guide: http://nco.sourceforge.net/nco.html
2. ESMF_RegridWeightGen (ERWG) user guide: http://www.earthsystemmodeling.org/esmf_releases/public/ESMF_6_3_0rp1/ESMF_refdoc/node3.html#SECTION03020000000000000000

--Min Xu @ORNL May 12 2016
