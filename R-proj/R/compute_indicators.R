#' Compute an indicator for each time period that describes the state of a market.
#'
#' Given a matrix that contains row-wise the assets' returns and a sliding window W, this function computes an approximation of the joint distribution (copula) between portfolios' return and volatility in each time period implied by W. 
#' For each copula it computes an indicator: large value corresponds to a crisis period and a small value to a normal period. 
#' The periods over which the indicator is greater than 1 for more than 60 consecutives sliding windows are warnings and for more than 100 are crisis. The sliding window is shifted by one day.
#'
#' @param returns A \eqn{d}-dimensional vector that describes the direction of the first family of parallel hyperplanes.
#' @param win_length Optional. The length of the sliding window. The default value is 60.
#' @param m Optional. The number of slices for the copula. The default value is 100.
#' @param n Optional. The number of points to sample. The default value is \eqn{5\cdot 10^5}.
#'
#' @references \cite{L. Cales, A. Chalkis, I.Z. Emiris, V. Fisikopoulos,
#' \dQuote{Practical volume computation of structured convex bodies, and an application to modeling portfolio dependencies and financial crises,} \emph{Proc. of Symposium on Computational Geometry, Budapest, Hungary,} 2018.}
#'
#' @return A list that contains the indicators and the corresponding vector that label each time period with respect to the market state: a) normal, b) crisis, c) warning.
#'
#' @export
compute_indicators <- function(returns, win_length = NULL, m = NULL, n = NULL) {
  
  if (is.null(win_length)) win_length = 60
  if (is.null(m)) m = 100
  if (is.null(n)) n = 500000
  
  nrows = dim(returns)[1]
  nassets = dim(returns)[2]
  wl = win_length-1
  
  indicators = c()
  for (i in 1:(nrows-wl)) {
    
    Win=i:(i+wl)
    E = cov(returns[Win,])
    
    compRet = rep(1,nassets)
    for (j in 1:nassets) {
      for (k in Win) {
        compRet[j] = compRet[j] * (1 + returns[k, j])
      }
      compRet[j] = compRet[j] - 1
    }
    
    cop = copula(r1 = compRet, sigma = E, m = m, n = n)
    blue_mass = 0
    red_mass = 0
    
    for (row in 1:m) {
      for (col in 1:m) {
        if (row-col<=0.2*m && row-col>=-0.2*m) {
          if (row+col<0.8*m || row+col>1.2*m) {
            red_mass = red_mass + cop[row,col]
          }
        } else {
          if (row+col>=0.8*m+1 && row+col<=1.2*m+1) {
            blue_mass = blue_mass + cop[row,col]
          }
        }
      }
    }
    indicators = c(indicators, blue_mass / red_mass)
  }

  N = length(indicators)

  index = 0
  set_index = FALSE
  col = rep("normal", N)

  for (i in 1:N) {
  
    if(indicators[i]>1 && !set_index){
      index = i
      set_index = TRUE
    } else if (indicators[i]<1) {
      if(set_index){
        if(i-index+1>30 && i-index+1<60){
          col[index:i] = "warning"
        } else if(i-index+1>60) {
          col[index:i] = "crisis"
        }
      }
      set_index = FALSE
    }
  }
  
  return(list("indicators" = indicators, market_states = col))
  
}
