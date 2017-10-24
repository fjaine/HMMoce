#' Smoother recursion over filtered state estimates
#' 
#' \code{hmm.smoother} provides backward (starting at end) recursion over 
#' filtered state estimates as output from \code{hmm.filter}. The product of 
#' this function an array containing final state estimates.
#' 
#' @param f is array output from \code{hmm.filter}
#' @param K1 is movement kernel generated by \code{gausskern} for behavior state
#'   1
#' @param K2 is movement kernel generated by \code{gausskern} for behavior state
#'   2
#' @param P is transition matrix (usually 2x2) representing probability of state
#'   switching
#' @param L is likelihood array output from \code{make.L}
#'   
#' @return an array of the final state estimates of dim(state, time, lon, lat)
#' @export
#' 

hmm.smoother.mod <- function(f, K1, K2, L, P, g, bathy){
  ## Smoothing the filtered estimates
  ## The equations for smoothing are presented in Pedersen et al. 2011, Oikos, Appendix
  T <- dim(f$phi)[2]
  row <- dim(f$phi)[3]
  col <- dim(f$phi)[4]
  lon <- g$lon[1,]
  lat <- g$lat[,1]
  
  # convert movement kernel from matrix to cimg for convolution
  K1 <- imager::as.cimg(K1)
  K2 <- imager::as.cimg(K2)
  
  smooth <- array(0, dim = dim(f$phi))
  smooth[,T,,] <- f$phi[,T,,]
  
  #smooth <- f$phi  #default; fill in as the prediction step.
  
  for(t in T:2){
    print(t)
    RAT <- smooth[,t,,] / (f$pred[,t,,] + 1e-15)
    
    # convolve today's smoother prediction with movement kernel
    p1 = imager::as.cimg(t(RAT[1,,]))
    Rp1 <- imager::convolve(p1, K1)
    p2 = imager::as.cimg(t(RAT[2,,]))
    Rp2 <- imager::convolve(p2, K2)
    Rp1 = t(as.matrix(Rp1))
    Rp2 = t(as.matrix(Rp2))
    
    if (t != T){
      # bathy mask the convolved products
      r1 <- raster::flip(raster::raster(t(Rp1), xmn=min(lon), xmx=max(lon), ymn=min(lat), ymx=max(lat),
                                        crs), 2)
      r2 <- raster::flip(raster::raster(t(Rp2), xmn=min(lon), xmx=max(lon), ymn=min(lat), ymx=max(lat),
                                        crs), 2)
      if (t == 2){
        bathy <- raster::resample(bathy, r1)
        bathy[bathy >= 0] <- NA
        bathy[bathy < 0] <- 1
      } 
      
      Rp1 <- t(raster::as.matrix(raster::flip((r1 * bathy),2)))
      Rp1[is.na(Rp1)] <- 1e-15
      Rp2 <- t(raster::as.matrix(raster::flip((r2 * bathy),2)))
      Rp2[is.na(Rp2)] <- 1e-15
    }
    
    post1 <- matrix(P[1,1] * Rp1 + P[1,2] * Rp2, row, col)
    post2 <- matrix(P[2,1] * Rp1 + P[2,2] * Rp2, row, col)
    
    if(T == t){
      post1 <- f$phi[1,t,,] * 0
      post2 <- L[t,,]
      fac <- sum(as.vector(post1), na.rm=T) + sum(as.vector(post2), na.rm=T)
      smooth[1,t,,] <- post1 / fac
      smooth[2,t,,] <- post2 / fac 
      post1 <- post1 * f$phi[1,t-1,,]
      post2 <- post2 * f$phi[2,t-1,,]
      fac <- sum(as.vector(post1), na.rm=T) + sum(as.vector(post2), na.rm=T)
      smooth[1,t-1,,] <- post1 / fac
      smooth[2,t-1,,] <- post2 / fac
    }else{
      post1 <- post1 * f$phi[1,t-1,,]
      post2 <- post2 * f$phi[2,t-1,,]
      fac <- sum(as.vector(post1), na.rm=T) + sum(as.vector(post2), na.rm=T)
      smooth[1,t-1,,] <- post1 / fac
      smooth[2,t-1,,] <- post2 / fac
    }
  }
  
  smooth
  
}
