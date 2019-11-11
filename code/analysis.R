source("helpers.R")

## indeces for time-varying covariates up to wave `n`
tvcols.upto = function(n) unlist(map(tv.cols, function(x) expand.ind.upto(x, n)))
