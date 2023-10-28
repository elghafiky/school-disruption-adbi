******************************************************************************
* ANALYSIS OF KELUD INCLUDING MERAPI AS TREATMENT
******************************************************************************

* install command 
// ssc install psmatch2
// ssc install estout	

capture log close
log using "$log\keludxmerapi.smcl", replace

** MATCHING ***************************************************************
use "$final/ifls-kelud.dta", clear

gen treatment_kelud = 1 if treat_ml_120<3 
replace treatment_kelud = 0 if treat_ml_120 == 3

local covariates sex age urban hhsize sex_hhhead  ///
length_schooling_father age_father islam_father jobstat_father_? ///
length_schooling_mother age_mother islam_mother  jobstat_mother_? ///
industry_growth family_card electricity

psmatch2 treatment_kelud `covariates' if year == 2007 , common
psgraph 
gr export "$figures/psgraph-keludxmerapi.png", replace
pstest `covariates', scatter outlier treated(_treated) both
gr export "$figures/pstest-keludxmerapi.png", replace

* check how many are dropped
tab _treated treatment_kelud if year == 2007, mis matcell(kelud)

* fill the treatment value with _treated in 2007	
bys pidlink (year) : replace _treated = _treated[_n-1] if _treated == . 
	
* tabulate post-matching sample size
estpost tab _treated
eststo kelud

* prepping variables for estimation
g distance=.
foreach x in merapi kelud galunggung salak raung {
	replace distance=`x'_distance if radius_`x'_120==1
}
replace distance=galunggung_distance if radius_galunggung_120==1 & radius_salak_120==1 & galunggung_distance>salak_distance
replace distance=salak_distance if radius_galunggung_120==1 & radius_salak_120==1 & galunggung_distance<salak_distance
		
egen district = group(idprov idkab)
egen hamlet = group(idprov idkab idkec)
encode pidlink, gen(pidlinkx)

** ESTIMATION ***************************************************************
	
* main
est clear
eststo regkxm: bootstrap, rep(1000): areg in_school c.distance##i.year##_treated `covariates' latitude longitude , robust cluster(district) absorb(pidlinkx)
estadd scalar n = e(N)
estadd scalar r2a =  e(r2_a) 
	
log close