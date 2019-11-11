#Load packages
library(foreign)
library(dplyr)
## library(fastDummies)

#Load data
df <- read.spss('../randhrs1992_2016v1_SPSS/randhrs1992_2016v1.sav')

#Only includes people born in 1931 - 1941  
df <- df %>%  
  as.data.frame() %>% 
  filter(RACOHBYR == '3.Hrs')

#Drop columns for W13,we only care about up to W12 (2014)
df <- select(df, -contains('13'))

#ID, Baseline covariates, and death covariates:
#Age at enrollment, self-reported sex, self-reported race/ethnicity (non-Hispanic black, non-Hispanic white, Hispanic, or other race),
#educational attainment (in years), household net worth, 
#health behaviors including smoking status, alcohol consumption, physical activity, and body mass index
bl_covariates <- c("HHIDPN","R1AGEM_E","R1AGEY_E","RAGENDER",
                   "RARACEM","RAHISPAN","RAEDYRS","H1ATOTW","R1SMOKEV",
                   "R1SMOKEN","R3DRINKD","R1LTACTF","R1VGACTF",
                   "R1HSWRKF","R1BMI","R1RISK","R1BEQLRG","RADTIMTDTH",
                   "RADDATE")

#Time varying covariates + wealth:
#consumer price index-adjusted household income	marital status	
#labor force status	health insurance status	self-rated health	
#whether health limited the ability to work	hospitalization in the past 2 years	
#out-of-pocket health care costs over the past 2 years	
#history of any of 8 chronic conditions: 	hypertension	diabetes	heart disease	stroke	lung disease	cancer	psychiatric conditions	arthritis	
#multimorbidity (???2 chronic conditions)	
#limitations in any of 5 activities of daily living:	walking across room	getting in and out of bed	dressing	bathing	eating								
tv_covariates <- c(sprintf("R%dIEARN",1:12), sprintf("R%dMSTAT",1:12),
                   sprintf("R%dLBRF",1:12), sprintf("R%dHIGOV",1:12),
                   sprintf("R%dPRPCNT",1:12), sprintf("R%dCOVR",1:12),
                   sprintf("R%dHIOTHP",1:12), sprintf("R%dSHLT",1:12),
                   sprintf("R%dHLTHLM",1:12), sprintf("R%dHOSP",1:12),
                   sprintf("R%dOOPMD",2:12), sprintf("R%dHIBPE",1:12),
                   sprintf("R%dDIABE",1:12), sprintf("R%dHEARTE",1:12),
                   sprintf("R%dSTROKE",1:12), sprintf("R%dLUNGE",1:12),
                   sprintf("R%dCANCRE",1:12), sprintf("R%dPSYCHE",1:12),
                   sprintf("R%dARTHRE",1:12), sprintf("R%dWALKRA",2:12),
                   sprintf("R%dBEDA",2:12), sprintf("R%dDRESSA",2:12),
                   sprintf("R%dBATHA",2:12), sprintf("R%dEATA",2:12),
                   sprintf("H%dATOTW",1:12))

#Subset the df
df <- select(df, bl_covariates, tv_covariates)

write.csv(df, "../data/data-cleaned.csv")


## #Create dummy columns
## final <- dummy_cols(df)
