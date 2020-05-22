# For longitudinal matching, we check balance at each time a "psuedo-experiment" was carried out (treatment times)
# For the unmatched data, treated are those experiencing treatment in that treatment time and control includes all individuals 
### that have not yet experienced treatment
# For matched data, treated and control correspond to the treated and control in that treatment period
# We check balance for the covariates in the time directly preceeding treatment

# Load data and functions/libraries
source("helpers.R")
data_stacked = read.csv("../data/data-stacked.csv")
results_final = read.csv('../data/results-final.csv')

# Select the columns we want to check for balance on
balance_cols = colnames(data_stacked)[4:ncol(data_stacked)]

# Start with W = 3
### TODO: Generalize this to user input W

### Subset data
before.treated = subset(data_stacked, W == 3 & FIRST_WS == 3)[ ,balance_cols]
before.control = subset(data_stacked, W == 3 & (FIRST_WS == 1 | FIRST_WS > 3))[ ,balance_cols]
after.treated = subset(results_final, treated_wave == 3 & treated == 1)[ ,balance_cols]
after.control = subset(results_final, treated_wave == 3 & treated == 0)[ ,balance_cols]

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

## Making table standardized differences
standBeforeAfter = cbind(stdiff.before, stdiff.after)
colnames(standBeforeAfter) = c("Before Match (Standardized Diff)",
                                "After Match (Standardized Diff)")
knitr::kable(round(abs(standBeforeAfter),3), caption = "Differences in Covariates (Before and After)") 

### Love Plot
abs.stand.diff.before=abs(stdiff.before)
abs.stand.diff.after=abs(stdiff.after)
covariates=names(stdiff.before)

plot.dataframe = data.frame(abs.stand.diff=c(abs.stand.diff.before,abs.stand.diff.after), covariates=rep(covariates,2), type=c(rep("Before",length(covariates)), rep("After",length(covariates))))

p1 = ggplot(plot.dataframe,aes(x=abs.stand.diff,y=covariates))+geom_point(size=5,aes(shape=factor(type)))+scale_shape_manual(values=c(4,1))+geom_vline(xintercept=c(.1,.2),lty=2)