#' Resample likelihood rasters to common resolution/extent
#' 
#' @param L.rasters list of individual likelihood rasters generated by calc 
#'   functions
#' @param L.resol raster or raster brick indicating desired output resolution of
#'   all likelihood rasters.
#' @param ncores is integer indicating number of cores used in this parallel 
#'   computation. Defaults to using a detection function that chooses cores for 
#'   you.
#'   
#' @return a list of all resampled likelihood rasters and g, the common grid
#' @export
#' @importFrom foreach "%dopar%"
#' @note This function should probably only be used in special use cases.
#'   Otherwise, the non-parallel version \code{\link{resample.grid}} is
#'   typically faster.
#'   


resample.grid.par <- function(L.rasters, L.resol, ncores = NULL){
  
  L.rasters.old <- L.rasters
  n <- length(L.rasters)
  
  # BEGIN PARALLEL STUFF  
  
  if (is.null(ncores)) ncores <- ceiling(parallel::detectCores() * .9)
  if (is.na(ncores) | ncores < 0) ncores <- ceiling(as.numeric(system('nproc', intern=T)) * .9)
  
  print('processing in parallel... ')
  
  # ncores = detectCores()  # should be an input argument
  cl = parallel::makeCluster(ncores)
  doParallel::registerDoParallel(cl, cores = ncores)
  
  ans = foreach::foreach(i = 1:n) %dopar%{
    #for (i in 1:length(L.rasters)){
      r <- L.rasters[[i]]
      
      #t <- Sys.time()
      r <- raster::resample(r, L.resol)
      #print(Sys.time() - t)
      r[r == 0] <- NA
      L.rasters[[i]] <- r
    
  }
    
  parallel::stopCluster(cl)

  # fill in L.hycom from the list output
  Lnames <- names(L.rasters)
  L.rasters.resamp <- ans
  names(L.rasters.resamp) <- Lnames

  # find mle raster
  resol <- rep(0, n)
  for (i in 1:n){
    resol[i] <- raster::res(L.rasters.old[[i]])[1]
  }

  L.mle.res <- L.rasters.old[which.max(resol)][[1]]
  
  g <- setup.grid.raster(L.resol)
  g.mle <- setup.grid.raster(L.mle.res)
  
  list(L.rasters.resamp, L.mle.res = L.mle.res, g = g, g.mle = g.mle)
  
}
