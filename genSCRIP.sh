# Examples of using ncks to generate grids

# 180x360 (1x1 degree) Equi-Angular grid, first longitude west bound at Greenwich 
ncks --rgr grd_ttl='Equi-Angular grid 180x360'#latlon=180,360#lat_typ=uni#lon_typ=grn_wst \
     --rgr scrip=180x360_SCRIP.20150901.nc in.nc ~/foo.nc



# 360x720 (0.5x0.5 degree) Equi-Angular grid, first longitude west bound at Greenwich
ncks --rgr grd_ttl='Equi-Angular grid 360x720'#latlon=360,720#lat_typ=uni#lon_typ=grn_wst \
     --rgr scrip=360x720_SCRIP.20150901.nc in.nc ~/foo.nc


# 720x1440 (0.25x0.25 degree) Equi-Angular grid, first longitude west bound at Greenwich
ncks --rgr grd_ttl='Equi-Angular grid 720x1440'#latlon=720,1440#lat_typ=uni#lon_typ=grn_wst \
     --rgr scrip=720x1440_SCRIP.20150901.nc in.nc ~/foo.nc
