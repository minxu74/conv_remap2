
# 180x360 (1x1 degree) Equi-Angular grid, first longitude centered at Greenwich
ncks --rgr grd_ttl='Equi-Angular grid 180x360'#latlon=180,360#lat_typ=uni#lon_typ=grn_ctr \
     --rgr scrip=180x360_SCRIP.20150901.nc in.nc ~/foo.nc



# 360x720 (1x1 degree) Equi-Angular grid, first longitude centered at Greenwich
ncks --rgr grd_ttl='Equi-Angular grid 360x720'#latlon=360,720#lat_typ=uni#lon_typ=grn_ctr \
     --rgr scrip=360x720_SCRIP.20150901.nc in.nc ~/foo.nc


# 360x720 (1x1 degree) Equi-Angular grid, first longitude centered at Greenwich
ncks --rgr grd_ttl='Equi-Angular grid 720x1440'#latlon=720,1440#lat_typ=uni#lon_typ=grn_ctr \
     --rgr scrip=720x1440_SCRIP.20150901.nc in.nc ~/foo.nc
