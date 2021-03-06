## This is the script for merging the matched pairs with their covariate/outcome data for analysis.
## The result is saved in data/results-final.csv.

#Load data and functions
matched_pairs = read.csv('../data/matched-pairs.csv')
df_stacked = read.csv('../data/data-stacked.csv')
df_cleaned = read.csv('../data/data-cleaned.csv')
source("helpers.R")

#Create matched pair ID & treatment wave
matched_pairs$pair_ID = seq.int(nrow(matched_pairs))
matched_pairs = left_join(matched_pairs, 
                          unique(df_stacked[c("HHIDPN","FIRST_WS")]),
                          by = c("treated" = "HHIDPN")) %>%
  rename(treated_wave = FIRST_WS) 
matched_pairs$cov_wave = (matched_pairs$treated_wave - 1)

#Temporarily turn living RADYEAR to 3000 to create outcome
df_cleaned$RADYEAR = ifelse(is.na(df_cleaned$RADYEAR), 3000, df_cleaned$RADYEAR)

#Create outcome variable
### -1 = control outlived treatment, 0 = died at same time, 1 = treatment outlived control
matched_pairs = left_join(matched_pairs,
                          unique(df_cleaned[c("HHIDPN","RADYEAR")]),
                          by = c("treated" = "HHIDPN")) %>%
  left_join(unique(df_cleaned[c("HHIDPN","RADYEAR")]),
            by = c("control" = "HHIDPN"), suffix = c("_treated", "_control"))
matched_pairs = mutate(matched_pairs,
                       outcome = case_when(
                         #No difference
                         RADYEAR_treated == RADYEAR_control ~ 0,
                         #Control lives longer than treatment
                         RADYEAR_treated < RADYEAR_control  ~ -1,
                         #Treatment lives longer than control
                         RADYEAR_treated > RADYEAR_control  ~ 1
                       )
)

#Create a seperate row for each observation
results_final = bind_rows(matched_pairs, matched_pairs, .id = "origin") %>%
  mutate(HHIDPN = case_when(
    origin == 1 ~ treated,
    origin == 2 ~ control
  ),
  RADYEAR = ifelse(origin == 1, RADYEAR_treated, RADYEAR_control)) %>%
  dplyr::select(HHIDPN, origin, pair_ID, cov_wave, treated_wave, outcome, RADYEAR)

#Create the treatment indicator
results_final = mutate(results_final, treated = ifelse(origin == 1, 1, 0)) %>%
  dplyr::select(HHIDPN, pair_ID, treated, outcome, cov_wave, treated_wave, RADYEAR)

#Join the covariates
results_final = left_join(results_final, df_stacked,
                          by = c("HHIDPN" = "HHIDPN", "treated_wave" = "W"))

#Return RADYEAR back to NA if they're still living
results_final$RADYEAR = ifelse(results_final$RADYEAR == 3000, NA, results_final$RADYEAR)

#Save the results
write.csv(results_final,'../data/results-final.csv', row.names = FALSE)

#Create a dataset to check balance
bl.cols = colnames(df_stacked)
bl.cols = bl.cols[c(1,3,14:28)]
initial_balance = unique(df_stacked[bl.cols])
write.csv(initial_balance,'../data/initial-balance.csv', row.names = FALSE)