require(tidyverse)

df = read.csv('../data/data-subset.csv')

#Combine race + ethnicity
df <- mutate(df, RACE_ETHN =
               case_when(
                 RAHISPAN == "1.Hispanic" ~ "Hispanic",
                 RARACEM == "1.White/Caucasian" ~ "NonHispWhite",
                 RARACEM == "2.Black/African American" ~ "NonHispBlack",
                 RARACEM == "3.Other" ~ "NonHispOther"
                 )
             ) %>% select(-RAHISPAN, -RARACEM)

#Determine people that started with negative wealth
df$BASELINE_POVERTY = df$H1ATOTW < 0

#Calculate wealth shock
for (i in 1:11){
  old_wealth = paste0("H",i,"ATOTW")
  new_wealth = paste0("H",i+1,"ATOTW")
  equation = paste0("df$",new_wealth,"/df$",old_wealth," <= 0.25")
  ws = eval(parse(text=equation))
  df[paste0("WS",i+1)] = ws
}

## expand a vector of index variable (e.g. "HwATOTB") into a vector of
## index variables for different waves (e.g. c("H1ATOTB", ...,
## "H13TOTB"))
expand.indeces <- function(svec) {
    expand.single = function(str) {
        if (str_detect(str, "w"))
            return(map_chr(1:12,
                           function(n) str_replace(str, "w", as.character(n))))
        else
            return(str)
    }
    unlist(map(svec, expand.single))
}

## create variables for "chronic conditions" and "multimorbidity"
## called "RwCHRCOND" and "RwMLTMORB"
diseases = c("RwHIBPE", "RwDIABE", "RwHEARTE", "RwSTROKE", "RwLUNGE", "RwCANCRE", "RwPSYCHE", "RwARTHRE")
for (w in 1:12) {
    rw.dis = select(df, one_of(str_replace(diseases, "w", as.character(w))))
    rw.dis.ind = apply(rw.dis, 1, function(x) c(any(x == "1.Yes")))
    rw.multi = apply(rw.dis, 1, function(x) c(sum(x == "1.Yes") >= 2))
    eval(parse(text = paste0("df$", "R", w, "CHRCOND=rw.dis.ind")))
    eval(parse(text = paste0("df$", "R", w, "MLTMORB=rw.multi")))
}
df = select(df, -one_of(expand.indeces(diseases)))


## create variable for "limitations in ADLs", called "RwLIMADL"
adls = c("RwWALKRA", "RwBEDA", "RwDRESSA", "RwBATHA", "RwEATA")
for (w in 2:12) {
    rw.adl = select(df, one_of(str_replace(adls, "w", as.character(w))))
    rw.adl.ind = apply(rw.adl, 1, function(x) c(any(x == "1.Yes")))
    eval(parse(text = paste0("df$", "R", w, "LIMADL=rw.adl.ind")))
}
df = select(df, -one_of(expand.indeces(adls)))
