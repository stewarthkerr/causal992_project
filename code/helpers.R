require(tidyverse)

bl.cols <- c("HHIDPN","R1AGEM_E","R1AGEY_E","RAGENDER",
             "RARACEM","RAHISPAN","RAEDYRS","H1ATOTW","R1SMOKEV",
             "R1SMOKEN","R3DRINKD","R1LTACTF","R1VGACTF",
             "R1HSWRKF","R1BMI","R1RISK","R1BEQLRG","RADTIMTDTH",
             "RADDATE")

tv.cols <- c("RwIEARN", "RwMSTAT", "RwLBRF", "RwHIGOV", "RwPRPCNT",
             "RwCOVR", "RwHIOTHP", "RwSHLT", "RwHLTHLM", "RwHOSP",
             "RwOOPMD", "RwCHRCOND", "RwMLTMORB", "RwLIMADL")

## expand a particular index `str` into a vector of indeces upto wave `n`
expand.ind.upto = function(str, n) {
    ## up to 0 means no time-varying covariates
    if (n == 0) return(character(0))
    map_chr(1:n, function(k) str_replace(str, "w", as.character(k)))
}

## expand a vector of index variable (e.g. "HwATOTB") into a vector of
## index variables for different waves (e.g. c("H1ATOTB", ...,
## "H13TOTB"))
expand.indeces = function(svec) {
    expand.single = function(str) {
        if (str_detect(str, "w"))
            return(expand.ind.upto(str, 12))
        else
            return(str)
    }
    unlist(map(svec, expand.single))
}
