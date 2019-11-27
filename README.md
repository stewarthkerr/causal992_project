## Getting started
The CSV file `data/data-subset.csv` is the output of `dataprep.R`, so there is no need to rerun it. The CSV file `data/data-cleaned/csv` is the output of `datacleaning.R` in which several covariates are constructed and the data is further subsetted.

`helpers.R` contains a few helper functions for `analysis.R` and `datacleaning.R`.

## Functions
* `data.upto`: generate the data needed for analysis at wave `n`, see
  function documentation for details

## Structure of cleaned data
### Variables
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
