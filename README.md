## Introduction
Does experiencing a large wealth shock, defined as the loss of 75% or more of your total wealth in a two-year period, cause an increase in mortality rates for Americans in retirement age? This was the focus of the [Mendes de Leon et al. paper published in JAMA in 2018.](https://doi.org/10.1001/jama.2018.2055) Their study used the University of Michigan's Health and Retirement Study (HRS) data and a time-varying weighted IPW estimator to estimate this effect. For our project, we sought to reexamine their analysis using a different approach, specifically, [Rosenbaum et al.'s "Balanced Risk Set Matching"](https://doi.org/10.1198/016214501753208573). 


## Data
Data for the project comes from the most recent version of the University of Michigan's HRS study. We used the RAND edited version of the data. Mirroring the JAMA study, we included individuals from the first HRS wave, born between 1931 and 1941 and first interviewed in 1992, for our analysis. Within the data subdirectory, `dataprep.R` was run to subset this HRS cohort, producing the file `data/data-subset.csv`. The code `datacleaning.R` was then run to clean the data (`data/data-cleaned.csv`) and add additional columns of interest. Lastly, the code `datastack.R` was run to remove people with missing data and prepare the dataset that is used for matching. Note that covariates were lagged by 1 time period so that they proceded treatment.

### Structure of cleaned data
Below lowercase `w` is placeholder for wave, which ranges between 1 (1992) and 12 (2016) varying 2 years between each wave.

* Variables of interest
  * `HHIDPN` (person ID)
  * `RADYEAR` (year of death)
  * `WSw` (wealth shock at wave w, *constructed*)

* Baseline covariates
  * `RABYEAR`
  * `RAGENDER`
  * `RACE_ETHN` (race and ethnicity, *constructed*)
  * `RAEDYRS`
  * `H1ATOTW`
  * `R1SMOKEV`
  * `R1SMOKEN`
  * `R3DRINKD`
  * `R1LTACTF`
  * `R1VGACTF`
  * `R1HSWRKF`
  * `R1BMI`
  * `R1RISK`
  * `R1BEQLRG`

* Time-varying covariates
  * `RwIEARN`
  * `RwMSTAT`
  * `RwLBRF`
  * `RwHIGOV`
  * `RwPRPCNT`
  * `RwCOVR`
  * `RwHIOTHP`
  * `RwSHLT`
  * `RwHLTHLM`
  * `RwHOSP`
  * `RwOOPMD` (w in 3:12, R2 has 99% NA and is therefore dropped)
  * `RwCHRCOND` (chronic conditions, *constructed*)
  * `RwMLTMORB` (multimorbidity, *constructed*)
  * `RwLIMADL` (w in 2:12, limitations in ADL, *constructed*)

## Code
All of the code used for our analysis exists in the `code/` subdirectory.
* `dataprep.R` subsets the RAND HRS data to contain only subjects from the first cohort.
* `datacleaning.R` further subsets the data to remove individuals that began with negative assets or have missing data.
* `datastack.R` processes the data for performed the matching using `matching.jl`.
* `helpers.R` contains the functions we used for data processing and analysis
  * `data.upto`: This function subsets the data-cleaned dataframe to contain only individuals that were observed in a particular year.
* `matching.jl` contains the code used to perform the risk-set balanced matching.
* `resultsprep.R` prepares the matched pairs produced by `matching.jl` for analysis of treatment effect, balance, and sensitivity
* `treatment_effect_analysis.Rmd` estimates the treatment effect used a paired t-test and IPW estimator.
* `balance_analysis.Rmd` compares balance of baseline covariates before and after matching.
* `sensitivity_analysis.Rmd` examines how sensitive our analysis is to unobserved confounders.
  
