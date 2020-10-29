# This is the script for finding subgroups using the CART algorthim from the rpart package

# Choose which covariates to exact match on
exact_covariates = c("RSMOKEN", "RAGENDER_1.Male", "INITIAL_INCOME", "RSHLT")
#GOOD CANDIDATES ARE RSHLT, RSMOKEN, RHLTHLM

# Load data and functions/libraries
source("helpers.R")
results_final = read.csv('../data/results-final.csv')

### Subset results into treated and control
treated = filter(results_final, treated == 1) %>%
  dplyr::select(-treated) %>%
  arrange(pair_ID)
control = filter(results_final, treated == 0) %>%
  dplyr::select(-treated) %>%
  arrange(pair_ID)

#################################################################################
################################ Initial Tree ###################################
#################################################################################

# Find covariates that have exact matching
treated_covariates = treated[7:ncol(treated)]
control_covariates = control[7:ncol(control)]
exact_matches = names(which((colSums(abs(treated_covariates - control_covariates)) == 0)))

# For chosen covariates, find all pairs which have exact matching
exact_covariates_treated = dplyr::select(treated_covariates, one_of(exact_covariates))
exact_covariates_control = dplyr::select(control_covariates, one_of(exact_covariates))
exact_obs = which(rowSums(abs(exact_covariates_treated - exact_covariates_control)) == 0)

# Now, for those pairs which have exact matching on important covariates,
# create a CART data frame containing all exact matched covariates with outcome
treated_CART = filter(treated, pair_ID %in% exact_obs) %>%
  dplyr::select(pair_ID, outcome,
    one_of(exact_matches),
    one_of(exact_covariates))
control_CART = filter(control, pair_ID %in% exact_obs) %>%
  dplyr::select(pair_ID, outcome,
    one_of(exact_matches),
    one_of(exact_covariates))
matched_pairs = inner_join(treated_CART,control_CART, by = c("pair_ID","outcome",exact_matches,exact_covariates), suffix = c(".treated",".control"))

### Recode the outcome for CART (directionless)
CART_input = mutate(matched_pairs, CART_outcome = abs(outcome)) %>%
  dplyr::select(-pair_ID, -outcome)

###Make variables factors
CART_input = mutate_all(CART_input, factor)

#Build the preliminary CART
pre_tree = rpart(CART_outcome ~ ., data = CART_input)

#################################################################################
################################### Final Tree ##################################
#################################################################################

#Drop the exact matching covariates that are not used in the CART -- this can give us more matches
CART_covariates = names(pre_tree$variable.importance)
CART_covariates_treated = dplyr::select(treated_covariates, one_of(CART_covariates))
CART_covariates_control = dplyr::select(control_covariates, one_of(CART_covariates))
CART_exact_obs = which(rowSums(abs(CART_covariates_treated - CART_covariates_control)) == 0)

# Now, for those pairs which have exact matching on important covariates,
# create a CART data frame containing all exact matched covariates with outcome
treated_CART = filter(treated, pair_ID %in% CART_exact_obs) %>%
  dplyr::select(pair_ID, outcome,
                one_of(exact_matches),
                one_of(CART_covariates))
control_CART = filter(control, pair_ID %in% CART_exact_obs) %>%
  dplyr::select(pair_ID, outcome,
                one_of(exact_matches),
                one_of(CART_covariates))
matched_pairs = inner_join(treated_CART,control_CART, by = c("pair_ID","outcome",exact_matches,CART_covariates), suffix = c(".treated",".control"))
write.csv(matched_pairs, "../data/matched-pairs.CART.csv", row.names = FALSE)

### Recode the outcome for CART (directionless)
CART_input = mutate(matched_pairs, CART_outcome = abs(outcome)) %>%
  dplyr::select(-pair_ID, -outcome)

### Make variables factors
CART_input = mutate_all(CART_input, factor)

### Build the final CART
final_tree = rpart(CART_outcome ~ ., data = CART_input, model = TRUE)
rpart.plot(final_tree)

### This gets what leaf each pair ends on:
final_tree$frame$node = rownames(final_tree$frame)
leaves = final_tree$frame[final_tree$where, "node"]

### This extracts the dataframe used to build the CART tree
tree_df = final_tree$model

### This can be used to get the path of each leaf
path.rpart(final_tree, unique(leaves))

### Save the covariates used in CART
CART_covariates = names(final_tree$variable.importance)
write.csv(CART_covariates, "../data/CART-covariates.csv", row.names = FALSE)

# ###################################EXTRA###################################
# 
# ##note initial income level one only has 0 for response only one pair with this
# x <- subset(CART_input, INITIAL_INCOME==1)
# length(x$INITIAL_INCOME)
# 
# library(ggplot2)
# CART_input$CART_outcome <- as.factor(CART_input$CART_outcome)
# g1 <- ggplot(data=CART_input, aes(INITIAL_INCOME)) +
#   geom_bar(aes(fill=CART_outcome, group=CART_outcome, color=CART_outcome))
# g2 <- ggplot(data=CART_input, aes(RAGENDER_1.Male)) +
#   geom_bar(aes(fill=CART_outcome, group=CART_outcome, color=CART_outcome))
# g3 <- ggplot(data=CART_input, aes(RSMOKEV)) +
#   geom_bar(aes(fill=CART_outcome, group=CART_outcome, color=CART_outcome))
# g4 <- ggplot(data=CART_input, aes(RACE_ETHN_NonHispOther)) +
#   geom_bar(aes(fill=CART_outcome, group=CART_outcome, color=CART_outcome))
# g5 <- ggplot(data=CART_input, aes(RMSTAT_2.Married.spouse.absent)) +
#   geom_bar(aes(fill=CART_outcome, group=CART_outcome, color=CART_outcome))
# g6 <- ggplot(data=CART_input, aes(RMSTAT_6.Separated.divorced)) +
#   geom_bar(aes(fill=CART_outcome, group=CART_outcome, color=CART_outcome))
# 
# g1
# g2
# g3
# g4
# g5
# g6
