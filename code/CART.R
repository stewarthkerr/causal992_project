# This is the script for finding subgroups using the CART algorthim from the rpart package

# Load data and functions/libraries
source("helpers.R")
results_final = read.csv('../data/results-final.csv')

# Find covariates for which we have exact matching
### Subset results into treated and control
treated = filter(results_final, treated == 1) %>%
  select(-treated, -outcome) %>%
  arrange(pair_ID)
control = filter(results_final, treated == 0) %>%
  select(-treated, -outcome) %>%
  arrange(pair_ID)

# Extract covariates that have exact matching
treated_covariates = treated[6:ncol(treated)]
control_covariates = control[6:ncol(treated)]
exact_matches = names(which((colSums(abs(treated_covariates - control_covariates)) == 0)))

# For specified covariates, find all pairs which have exact matching
exact_covariates = c("RSMOKEV", "RAGENDER_1.Male","INITIAL_WEALTH_high","INITIAL_WEALTH_low")
exact_covariates_treated = select(treated_covariates, matches(paste(exact_covariates, collapse="|")))
exact_covariates_control = select(control_covariates, matches(paste(exact_covariates, collapse="|")))
exact_obs = which(rowSums(abs(exact_covariates_treated - exact_covariates_control)) == 0)

# Now, for those pairs which have exact matching on important covariates,
# create a CART data frame containing all exact matched covariates with outcome
treated_CART = filter(treated, pair_ID %in% exact_obs) %>%
  select(pair_ID, RADYEAR,
    matches(paste(exact_matches, collapse="|")),
    matches(paste(exact_covariates,collapse="|")))
control_CART = filter(control, pair_ID %in% exact_obs) %>%
  select(pair_ID, RADYEAR,
    matches(paste(exact_matches, collapse="|")),
    matches(paste(exact_covariates,collapse="|")))
matched_pairs = inner_join(treated_CART,control_CART, by = c("pair_ID",exact_matches,exact_covariates), suffix = c(".treated",".control"))

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
  select(-RADYEAR.treated, -RADYEAR.control, - pair_ID)

#Build the CART
tree = rpart(CART_outcome ~ ., data = CART_input)
rpart.plot(tree)

