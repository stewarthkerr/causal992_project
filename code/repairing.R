# Load data and functions/libraries
source("helpers.R")
matched_pairs.CART = read.csv('../data/matched-pairs.CART.csv')
CART_covariates = read.csv("../data/CART-covariates.csv", stringsAsFactors = FALSE)[['x']]
results_final = read.csv("../data/results-final.csv")
data_stacked = read.csv("../data/data-stacked.csv")

# Build the data to do matching while keeping treated and control
# We do an inner_join because we don't want to add back people who werent in the original match (to not mess with balance)
repair_IDs = results_final[results_final$pair_ID %in% matched_pairs.CART$pair_ID, "HHIDPN"]
repair_df = data_stacked[!(data_stacked$HHIDPN %in% repair_IDs), c("HHIDPN","W",CART_covariates)] %>%
  inner_join(select(results_final,HHIDPN,treated_wave,treated), by = c("HHIDPN" = "HHIDPN", "W" = "treated_wave"))

# Use optmatch to do the exact matching
em = exactMatch(as.formula(paste0("treated ~ W + ", paste0(CART_covariates, collapse = " + "))), data = repair_df)
pm = pairmatch(em, data = repair_df)
### This checks to make sure the order is the same
if (all.equal(names(pm), row.names(repair_df))){
  repaired_df = cbind(repair_df, pair_ID = pm) %>%
    filter(!is.na(pair_ID)) %>% ### Removes the people that don't have a match
    mutate(pair_ID = as.character(pair_ID)) ### Needed for the join below
}

# Calculate outcome for repaired individuals
repaired_df = filter(repaired_df, !is.na(pair_ID))
repaired_df = inner_join(repaired_df, select(results_final, HHIDPN, RADYEAR), by = "HHIDPN") %>%
  mutate(RADYEAR = ifelse(is.na(RADYEAR), 3000, RADYEAR)) ### This makes it easier to calculate outcome
repaired_treated = filter(repaired_df, treated == 1); repaired_control = filter(repaired_df, treated == 0) %>% select(pair_ID, RADYEAR)
repaired_df = inner_join(repaired_treated, repaired_control, by = "pair_ID", suffix = c("_treated", "_control")) %>%
  mutate(outcome = case_when(
    #No difference
    RADYEAR_treated == RADYEAR_control ~ 0,
    #Control lives longer than treatment
    RADYEAR_treated < RADYEAR_control  ~ -1,
    #Treatment lives longer than control
    RADYEAR_treated > RADYEAR_control  ~ 1)
  ) %>%
  select(pair_ID, outcome, CART_covariates)

# Combine repaired matches with original matches for final analysis set
out = rbind(matched_pairs.CART, repaired_df)
write.csv(out, "../data/matched-pairs-repaired.csv", row.names = FALSE)


