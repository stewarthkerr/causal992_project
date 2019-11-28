require(tidyverse)
require(fastDummies)

## expand a particular index `str` into a vector of indeces upto wave `n`
expand.ind.upto = function(str, start = 1, end) {
    ## up to 0 means no time-varying covariates
    if (end == 0) return(character(0))
    map_chr(start:end, function(k) str_replace(str, "w", as.character(k)))
}

## expand a vector of index variable (e.g. "HwATOTB") into a vector of
## index variables for different waves (e.g. c("H1ATOTB", ...,
## "H13TOTB"))
expand.indeces = function(svec, start = 1, end) {
    expand.single = function(str) {
        if (str_detect(str, "w"))
            return(expand.ind.upto(str, start, end))
        else
            return(str)
    }
    unlist(map(svec, expand.single))
}

#' Generate relevant columns for waves up to n-th wave
#'
#' @param df the cleaned data frame
#' @return the dataset for analysis at wave n there is a new column
#'     "priorWS" which indicates whether the person had wealth shock on
#'     or before wave n.  The response of interest is RADYEAR.
data.upto = function(df, n) {
  if (n <= 1 || n > 12) stop("Invalid wave number")
  
  ## Remove people with negative wealth to start with
  df = df[!(df$BASELINE_POVERTY),]
  
  ## Remove people that have already died
  df = df[!(df$DeathWave < n),]
  
  ## construct WS before indicator and remove those people
  wsinds = paste0("WS", 2:max(2,(n-1)))
  df$priorWS = apply(df[,wsinds,drop = FALSE],1,any)
  df = df[!(df$priorWS),]
  
  ## lag the time varying covariates
  tv.cols <- c("RwIEARN", "RwMSTAT", "RwLBRF", "RwHIGOV", "RwPRPCNT",
               "RwCOVR", "RwHIOTHP", "RwSHLT", "RwHLTHLM", "RwHOSP",
               "RwOOPMD", "RwCHRCOND", "RwMLTMORB", "RwLIMADL")
  tv.cols = unlist(purrr::map(tv.cols, function(x) expand.ind.upto(x, start = 1, end = n - 1)))
  tv.cols = intersect(tv.cols, names(df))
  bl.cols = c("RABYEAR","RAGENDER", "RACE_ETHN","RAEDYRS",
              "H1ATOTW","R1SMOKEV", "R1SMOKEN","R3DRINKD","R1LTACTF",
              "R1VGACTF", "R1HSWRKF","R1BMI","R1RISK","R1BEQLRG")
  special.cols = c("HHIDPN", "RADYEAR")
  cols = c(tv.cols, bl.cols, special.cols)
  
  ## construct data frame
  result = df[,cols]

  ##  remove people with NAs
  result = result[complete.cases(result[,c(tv.cols, bl.cols)]),]
  
  return(result)
} 
