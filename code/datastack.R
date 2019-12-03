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
            "R1VGACTF", "R1BMI","R1RISK","R1BEQLRG")
df_analysis = df[complete.cases(df[,c(bl.cols)]),]
df_analysis = df_analysis[!(df$BASELINE_POVERTY),]

for (wave in 2:12){
  ## Subset the data to this wave
  df_work = data.upto(df_analysis, wave)
  print(paste0("Wave: ", wave,", N (Treated+Control) = ",nrow(df_work)))
  
  ## Make sure the column names are standard
  colnames(df_work) = gsub('[0-9]+', '', colnames(df_work))
  
  ## Stack the data  
  if (wave == 2){
    df_stacked = df_work
  } else{
    df_stacked = rbind(df_stacked, df_work)
  }
} 

## Convert unordered columns to dummy_cols and remove RADYEAR
df_stacked = dummy_cols(df_stacked, 
                     select_columns = c("RAGENDER","RACE_ETHN","RMSTAT","RLBRF"), 
                     remove_most_frequent_dummy = TRUE) %>%
  select(-RAGENDER,-RACE_ETHN,-RMSTAT,-RLBRF, -RADYEAR)

## Convert the rest of the columns into numeric
df_stacked = sapply(df_stacked, as.numeric) #Converts all factors to their numeric level

## Save the data
write.csv(df_stacked,'../data/data-stacked.csv', row.names = FALSE)


