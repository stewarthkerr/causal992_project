require(tidyverse)

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
