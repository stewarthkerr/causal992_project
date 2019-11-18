source("helpers.R")

#' Generate relevant columns for waves up to n-th wave
#'
#' @param df the cleaned data frame
#' @return the dataset for analysis at wave n there is a new column
#'     "hasws" which indicates whether the person had wealth shock on
#'     or before wave n.  The response of interest is RADYEAR.
data.upto = function(df, n) {
    if (n <= 1 || n > 12) stop("Invalid wave number")
    ## lag the time varying covariates
    tv.cols <- c("RwIEARN", "RwMSTAT", "RwLBRF", "RwHIGOV", "RwPRPCNT",
                 "RwCOVR", "RwHIOTHP", "RwSHLT", "RwHLTHLM", "RwHOSP",
                 "RwOOPMD", "RwCHRCOND", "RwMLTMORB", "RwLIMADL")
    tv.cols = unlist(map(tv.cols, function(x) expand.ind.upto(x, n - 1)))
    tv.cols = intersect(tv.cols, names(df))
    bl.cols = c("RABYEAR","RAGENDER", "RACE_ETHN","RAEDYRS",
                "H1ATOTW","R1SMOKEV", "R1SMOKEN","R3DRINKD","R1LTACTF",
                "R1VGACTF", "R1HSWRKF","R1BMI","R1RISK","R1BEQLRG")
    special.cols = c("HHIDPN", "RADYEAR")
    cols = c(tv.cols, bl.cols, special.cols)

    ## construct WS before indicator
    wsinds = paste0("WS", 2:n)
    hasws = apply(df[,wsinds,drop = FALSE],1,any)

    ## construct data frame
    result = df[,cols]
    result$hasws = hasws
    
    ## remove people with negative wealth to start with
    result = result[!(df$BASELINE_POVERTY),]
    
    ##  remove people with NAs
    result = result[complete.cases(result[,c(tv.cols, bl.cols)]),]
}

## the sample sizes for each wave, from 2 to 12
sample.sizes = unlist(map(2:12, function(n) nrow(data.upto(df, n))))
