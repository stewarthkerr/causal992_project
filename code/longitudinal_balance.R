# For longitudinal matching, we check balance at each time a "psuedo-experiment" was carried out (treatment times)
# For the unmatched data, treated are those experiencing treatment in that treatment time and 
### control includes all individuals that have not yet experienced treatment
# For matched data, treated and control correspond to the treated and control in that treatment period
# We check balance for the covariates in the time directly preceeding treatment
# To get an overall measure of balance, take a weighted average of the balance for each treatment time
# reference: 10.1002/sim.8533 paragraph 5.3

# Load data and functions/libraries
source("helpers.R")
data_stacked = read.csv("../data/data-stacked.csv")
results_final = read.csv("../data/results-final.csv")

# Function to calculate longitudinal balance for a particular wave
longitudinal_balance = function(before_match, after_match, wave){
  
  ### Select the columns we want to check for balance on
  balance_cols = colnames(data_stacked)[4:ncol(data_stacked)]

  ### Subset data
  before.treated = subset(before_match, W == wave & FIRST_WS == wave)[ ,balance_cols]
  before.control = subset(before_match, W == wave & (FIRST_WS == -1 | FIRST_WS > wave))[ ,balance_cols]
  after.treated = subset(after_match, treated_wave == wave & treated == 1)[ ,balance_cols]
  after.control = subset(after_match, treated_wave == wave & treated == 0)[ ,balance_cols]
  
  ### Calculate means and variances
  before.treated.mean = apply(before.treated, 2, mean)
  before.control.mean = apply(before.control, 2, mean)
  after.treated.mean = apply(after.treated, 2, mean)
  after.control.mean = apply(after.control, 2, mean)
  before.treated.var = apply(before.treated, 2, var)
  before.control.var = apply(before.control, 2, var)
  after.treated.var = apply(after.treated, 2, var)
  after.control.var = apply(after.control, 2, var)
  
  ### Calculate standardized difference
  stdiff.before = (before.treated.mean - before.control.mean) / sqrt(0.5*(before.treated.var+before.control.var))
  stdiff.after = (after.treated.mean - after.control.mean) / sqrt(0.5*(after.treated.var+after.control.var))
  
  ### Return standardized difference vector
  return(data.frame(stdiff.before, stdiff.after))
}

### Test the function on a specific wave
test6 = longitudinal_balance(data_stacked, results_final, 6)
stdiff.before = test6$stdiff.before
stdiff.after = test6$stdiff.after

### Make table of standardized differences
standBeforeAfter = cbind(stdiff.before, stdiff.after)
colnames(standBeforeAfter) = c("Before Match (Standardized Diff)",
                                "After Match (Standardized Diff)")
knitr::kable(round(abs(standBeforeAfter),3), caption = "Differences in Covariates (Before and After)") 

### Make Love plot
abs.stand.diff.before = abs(stdiff.before)
abs.stand.diff.after = abs(stdiff.after)
covariates = colnames(data_stacked)[4:ncol(data_stacked)]

plot.dataframe = data.frame(abs.stand.diff=c(abs.stand.diff.before,abs.stand.diff.after), covariates=rep(covariates,2), type=c(rep("Before",length(covariates)), rep("After",length(covariates))))

p1 = ggplot(plot.dataframe,aes(x=abs.stand.diff,y=covariates))+geom_point(size=5,aes(shape=factor(type)))+scale_shape_manual(values=c(4,1))+geom_vline(xintercept=c(.1,.2),lty=2)