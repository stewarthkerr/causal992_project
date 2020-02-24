## This is the script for finding subgroups using the CART algorthim from the rpart package

#Load data and functions/libraries
source("helpers.R")
results_final = read.csv('../data/results-final-small.csv')

#Combine treated, control onto one row
treated = filter(results_final, treated == 1) %>%
  select(-treated, -outcome)
control = filter(results_final, treated == 0) %>%
  select(-treated, -outcome)
matched_pairs = inner_join(treated,control, by = "pair_ID", suffix = c(".treated", ".control"))

#Recode the outcome, -1 = control outlived treatment, 0 = died at same time, 1 = treatment outlived control
# -- later, do this in resultsprep.R, it's currently bugged
#Create CART outcome which is directionless
matched_pairs = mutate(matched_pairs, outcome = case_when(
  is.na(RADYEAR.treated) & is.na(RADYEAR.control) ~ 0,
  is.na(RADYEAR.treated) & !is.na(RADYEAR.control) ~ 1,
  !is.na(RADYEAR.treated) & is.na(RADYEAR.control) ~ -1,
  RADYEAR.treated == RADYEAR.control ~ 0,
  RADYEAR.treated < RADYEAR.control ~ -1,
  RADYEAR.treated > RADYEAR.control ~ 1
  ),
  CART_outcome = abs(outcome)
)

#Check for exact matching among covariates
treated_covariates = matched_pairs[6:43]
control_covariates = matched_pairs[48:85]
exact_matches = gsub(".treated","",names(which((colSums(abs(treated_covariates - control_covariates)) == 0))))
exact_matches_CART = names(which((colSums(abs(treated_covariates - control_covariates)) == 0)))

#Subset matched_pairs to keep only covariates with exact matching
matched_pairs_exact = select(matched_pairs, contains("HHIDPN"), contains("outcome"), matches(paste(exact_matches, collapse="|")))
CART_input = select(matched_pairs, CART_outcome, matches(paste(exact_matches_CART, collapse="|")))

#Build the CART
tree = rpart(CART_outcome ~ ., data = CART_input)
rpart.plot(tree)


################################################################################################################################
################################################################################################################################
################################################################################################################################
# Alternatively, we can choose certain covariates and select only pairs which have exact matching in that covariate
exact_covariates = c("RSMOKEV", "RAGENDER_1.Male")
treated_covariates_m2 = select(treated_covariates, matches(paste(exact_covariates, collapse="|")))
control_covariates_m2 = select(control_covariates, matches(paste(exact_covariates, collapse="|")))
exact_obs = which(rowSums(abs(treated_covariates_m2 - control_covariates_m2)) == 0)
matched_pairs_exact_m2 = select(matched_pairs, contains("HHIDPN"), contains("outcome"), matches(paste(exact_matches, collapse="|")), 
  matches(paste(exact_covariates, collapse="|")))[exact_obs,]
CART_input_m2 = select(matched_pairs, CART_outcome, matches(paste(exact_matches_CART, collapse="|")),
  matches(paste(paste0(exact_covariates,".treated"), collapse="|")))[exact_obs,]

#Build the new CART
tree_m2 = rpart(CART_outcome ~ ., data = CART_input_m2)
rpart.plot(tree_m2)

