# This is the script for finding subgroups using the CART algorthim from the rpart package
# TODO: Use mipmatch to do repairing

# Choose which covariates to exact match on
exact_covariates = c("RSMOKEN", "RAGENDER_1.Male", "INITIAL_INCOME", "RSHLT")
#GOOD CANDIDATES ARE RSHLT, RSMOKEN, RHLTHLM

# Load data and functions/libraries
source("helpers.R")
matched_pairs.CART = read.csv('../data/matched_pairs.CART.csv')
CART_covariates = read.csv("../data/CART-covariates.csv", stringsAsFactors = FALSE)[['x']]
results_final = read.csv("../data/results-final.csv")
data_stacked = read.csv("../data/data-stacked.csv")

# Build the data to do matching while keeping treated and control
# We do an inner_join because we don't want to add back people who werent in the original match (to not mess with balance)
repair_keys = results_final[results_final$pair_ID %in% matched_pairs.CART$pair_ID, c("HHIDPN","treated_wave")]
repair_df = data_stacked[!(data_stacked$HHIDPN %in% repair_IDs), c("HHIDPN","W",CART_covariates)] %>%
  inner_join(select(results_final,HHIDPN,treated_wave,treated), by = c("HHIDPN" = "HHIDPN", "W" = "treated_wave"))
write.csv(repair_df, "../data/data-repairing.csv", row.names = FALSE)
