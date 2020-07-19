#' Coerce irregular grid as nc to raster
#' 
#' Main purpose of this function is for converting bathymetry data that is typically acquired as an irregular grid
#' 
#' @param fname is input filename of the .nc file
#' @return a raster version of the input .nc file coerced to regular grid

irregular_ncToRaster <- function(fname, varid){
  
  nc <- RNetCDF::open.nc(fname)
  lon <- as.numeric(RNetCDF::var.get.nc(nc, variable = "longitude"))
  lat <- as.numeric(RNetCDF::var.get.nc(nc, variable = "latitude"))
  bdata <- RNetCDF::var.get.nc(nc, variable = varid)
  
  lat = lat[order(lat)]
  
  bathy = list(x = lon, y = lat, data = bdata)
  
  #if(raster){
    crs <- "+proj=longlat +datum=WGS84 +ellps=WGS84"
    ex <- raster::extent(bathy)
    bathy <- raster::raster(t(bathy$data), xmn = ex[1], xmx = ex[2], ymn = ex[3], ymx = ex[4], crs)
  #}
  
  bathy
  
}