## This is the script for cleaning the subsetting data.  The result is
## saved in data/data-cleaned.csv.  
df = read.csv('../data/data-subset.csv')

#Load functions
source("helpers.R")

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

#Code initial income into different levels
##R1IEARN:W1 Income:R Earnings
df$INITIAL_INCOME <- cut(df$R1IEARN, c(0,31000,42000,126000,188000,max(df$R1IEARN,na.rm = TRUE)), right=FALSE, include.lowest = TRUE, labels=c("low", "low-middle", "middle", "upper-middle", "high"))

#Code quantiles for initial wealth among those who started with non-negative wealth
wealth_quantiles = quantile(df[df$BASELINE_POVERTY==0,]$H1ATOTW, c(0,0.2,0.4,0.6,0.8,1.0), na.rm = TRUE)
df$INITIAL_WEALTH = cut(df$H1ATOTW, wealth_quantiles, right=FALSE, include.lowest = TRUE, labels=c("low", "low-middle", "middle", "upper-middle", "high"))

#Calculate wealth shock & first wealth shock
df$FIRST_WS = -1
for (i in 1:11){
  old_wealth = paste0("H",i,"ATOTW")
  new_wealth = paste0("H",i+1,"ATOTW")
  equation = paste0("df$",new_wealth,"/df$",old_wealth," <= 0.25")
  ws = eval(parse(text=equation))
  df[paste0("WS",i+1)] = ws
  
  df$FIRST_WS = ifelse(df$FIRST_WS == -1 & (!is.na(ws) & ws), i+1, df$FIRST_WS)
}

#Calculate wave of death
df$DeathWave = floor(1+((df$RADYEAR-1992)/2))

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
df = select(df, -one_of(expand.indeces(diseases, start = 1, end = 12)))


## create variable for "limitations in ADLs", called "RwLIMADL"
adls = c("RwWALKRA", "RwBEDA", "RwDRESSA", "RwBATHA", "RwEATA")
for (w in 2:12) {
    rw.adl = select(df, one_of(str_replace(adls, "w", as.character(w))))
    rw.adl.ind = apply(rw.adl, 1, function(x) c(any(x == "1.Yes")))
    eval(parse(text = paste0("df$", "R", w, "LIMADL=rw.adl.ind")))
}
df = select(df, -one_of(expand.indeces(adls, start = 2, end = 12)))


## creating NAs for time-varying covariates that doesn't exist in data
## (e.g. at wave 1)
## nevermind... this doesn't make sense
## nacovs = setdiff(expand.indeces(tv.cols), names(df))
## for (column in nacovs) eval(parse(text = paste0("df$", column, "=NA")))

#Remove columns we don't want
df$R2OOPMD = NULL
df$X = NULL
#Calculates % NA in each column
#narate = sort(unlist(purrr::map(df, function(x) mean(is.na(x)))), decreasing = T)

## Save data as 
df = write.csv(df,'../data/data-cleaned.csv', row.names = FALSE)
