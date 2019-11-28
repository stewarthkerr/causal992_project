#Load cleaned data
df = read.csv('../data/data-cleaned.csv')

#Load functions
source("helpers.R")

## the sample sizes for each wave, from 2 to 12
#sample.sizes = unlist(purrr::map(2:12, function(n) nrow(data.upto(df, n))))

#Remove people that are missing the baseline covariate
# or had negative wealth to begin
bl.cols = c("RABYEAR","RAGENDER", "RACE_ETHN","RAEDYRS",
            "H1ATOTW","R1SMOKEV", "R1SMOKEN","R3DRINKD","R1LTACTF",
            "R1VGACTF", "R1HSWRKF","R1BMI","R1RISK","R1BEQLRG")
df_analysis = df[complete.cases(df[,c(bl.cols)]),]
df_analysis = df_analysis[!(df$BASELINE_POVERTY),]

#Create a matrix that contains all the people who ever experienced treatment
df_analysis$hasws = apply(df_analysis[,paste0("WS", 2:12),drop = FALSE],1,any)
treated = filter(df_analysis, hasws)

#Create a matrix that contains all people that could possibly be a control
controls = filter(df_analysis, !WS2)

#Next, I think we should cycle through each wave sequentially
# and calculate distance for those treated in that wave and all
# their possible controls.
# If it's impossible for a treated person to match a specific control
# (ie the control has already had a treatment in a prior year) 
# we set the distance to Inf
# USE DUMMY_COLS()
for (wave in 2:12){
  #Subset the data to this wave
  df_work = data.upto(df_analysis, wave)
  print(paste0(wave,":",nrow(df_work)))
  
  #Convert the character/factor columns to dummy columns, drop the character/factor columns
} 

