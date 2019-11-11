# Structure of cleaned data
## Variables
Below lowercase `w` is placeholder for wave, which ranges between 1 and 12.

* Variables of interest
  * `HHIDPN` (person ID)
  * `RADYEAR` (year of death)
  * `WSw` (wealth shock at wave w, *constructed*)

* Baseline covariates
  * `RABYEAR`
  * `RAGENDER`
  * `RACE_ETHN` (race and ethnicity, *constructed*)
  * `RAHISPAN`
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
  * `RwOOPMD` (w in 2:12)
  * `RwCHRCOND` (chronic conditions, *constructed*)
  * `RwMLTMORB` (multimorbidity, *constructed*)
  * `RwLIMADL` (w in 2:12, limitations in ADL, *constructed*)


