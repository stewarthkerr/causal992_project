# This is the script for finding subgroups using the CART algorthim from the rpart package

# Load data and functions/libraries
source("helpers.R")
results_final = read.csv('../data/results-final.csv')

# Find covariates for which we have exact matching
### Subset results into treated and control
treated = filter(results_final, treated == 1) %>%
  dplyr::select(-treated, -outcome) %>%
  arrange(pair_ID)
control = filter(results_final, treated == 0) %>%
  dplyr::select(-treated, -outcome) %>%
  arrange(pair_ID)

# Extract covariates that have exact matching
treated_covariates = treated[6:ncol(treated)]
control_covariates = control[6:ncol(treated)]
exact_matches = names(which((colSums(abs(treated_covariates - control_covariates)) == 0)))

# For specified covariates, find all pairs which have exact matching
exact_covariates = c("RSMOKEV", "RAGENDER_1.Male","INITIAL_INCOME")
exact_covariates_treated = dplyr::select(treated_covariates, one_of(exact_covariates))
exact_covariates_control = dplyr::select(control_covariates, one_of(exact_covariates))
exact_obs = which(rowSums(abs(exact_covariates_treated - exact_covariates_control)) == 0)

# Now, for those pairs which have exact matching on important covariates,
# create a CART data frame containing all exact matched covariates with outcome
treated_CART = filter(treated, pair_ID %in% exact_obs) %>%
  dplyr::select(pair_ID, RADYEAR,
    one_of(exact_matches),
    one_of(exact_covariates))
control_CART = filter(control, pair_ID %in% exact_obs) %>%
  dplyr::select(pair_ID, RADYEAR,
    one_of(exact_matches),
    one_of(exact_covariates))
matched_pairs = inner_join(treated_CART,control_CART, by = c("pair_ID",exact_matches,exact_covariates), suffix = c(".treated",".control"))
matched_pairs.CART = write.csv(matched_pairs, '../data/matched_pairs.CART.csv', row.names = FALSE)

### Recode the outcome, -1 = control outlived treatment, 0 = died at same time, 1 = treatment outlived control
### -- later, do this in resultsprep.R, it's currently bugged
### Create CART outcome which is directionless
CART_input = mutate(matched_pairs, CART_outcome = case_when(
  is.na(RADYEAR.treated) & is.na(RADYEAR.control) ~ abs(0),
  is.na(RADYEAR.treated) & !is.na(RADYEAR.control) ~ abs(1),
  !is.na(RADYEAR.treated) & is.na(RADYEAR.control) ~ abs(-1),
  RADYEAR.treated == RADYEAR.control ~ abs(0),
  RADYEAR.treated < RADYEAR.control ~ abs(-1),
  RADYEAR.treated > RADYEAR.control ~ abs(1))
) %>%
  dplyr::select(-RADYEAR.treated, -RADYEAR.control, - pair_ID)

###Make variables factors and only include Initial Income
CART_input = mutate_all(CART_input, factor)

#Build the CART
tree = rpart(CART_outcome ~ ., data = CART_input)
rpart.plot(tree)

