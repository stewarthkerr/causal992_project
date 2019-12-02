#Load data and functions
matched_pairs = read.csv('../data/matched-pairs.csv')
df_stacked = read.csv('../data/data-stacked.csv')
source("helpers.R")

#Create matched pair ID & treatment wave
matched_pairs$pair_ID = seq.int(nrow(matched_pairs))
matched_pairs = left_join(matched_pairs, 
                          unique(df_stacked[c("HHIDPN","FIRST_WS")]),
                          by = c("treated" = "HHIDPN")) %>%
  rename(cov_wave = FIRST_WS) 
matched_pairs$cov_wave = (matched_pairs$cov_wave - 1)

#Create outcome variable
matched_pairs = left_join(matched_pairs,
                          unique(df_stacked[c("HHIDPN","RADYEAR")]),
                          by = c("treated" = "HHIDPN")) %>%
  left_join(unique(df_stacked[c("HHIDPN","RADYEAR")]),
            by = c("control" = "HHIDPN"), suffix = c("_treated", "_control"))
matched_pairs = mutate(matched_pairs,
                       outcome = case_when(
                         #No difference
                         RADYEAR_treated == RADYEAR_control ~ -1,
                         #Control lives longer than treatment
                         RADYEAR_treated < RADYEAR_control  ~ 1,
                         #Treatment lives longer than control
                         RADYEAR_treated > RADYEAR_control  ~ 0
                         )
                       )

#Create a seperate row for each observation
results_final = bind_rows(matched_pairs, matched_pairs, .id = "origin") %>%
  mutate(HHIDPN = case_when(
    origin == 1 ~ treated,
    origin == 2 ~ control
    ),
    outcome = case_when(
      outcome == -1              ~ -1,
      origin == 1 & outcome == 1 ~ 0,
      origin == 1 & outcome == 0 ~ 1,
      origin == 2 & outcome == 1 ~ 1,
      origin == 2 & outcome == 0 ~ 0
    )
  ) %>%
  select(HHIDPN, origin, pair_ID, cov_wave, outcome)

#Create the treatment indicator
results_final = mutate(results_final, treated = ifelse(origin == 1, 1, 0)) %>%
  select(HHIDPN, pair_ID, treated, outcome, cov_wave)

#Join the covariates
results_final = left_join(results_final, df_stacked,
                          by = c("HHIDPN" = "HHIDPN", "cov_wave" = "W")) %>%
  select(-X)

#Save the results
write.csv(results_final,'../data/results-final.csv')
