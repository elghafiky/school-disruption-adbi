******************************************************************************
* ANALYSIS OF SEPARATE VOLCANOES (UNMATCHED SAMPLE)
******************************************************************************

* install command 
// ssc install estout	

capture log close
log using "$log\analysis_unmatched_all.smcl", replace

** ESTIMATION ***************************************************************
local covariates sex age urban hhsize sex_hhhead  ///
length_schooling_father age_father islam_father jobstat_father_? ///
length_schooling_mother age_mother islam_mother jobstat_mother_? ///
industry_growth family_card electricity

foreach mount in "merapi" "kelud" {
	
	loc mp = strupper("`mount'")
	di as text _dup(59) "-" ///
	_n as res "MOUNT `mp'" ///
	_n as text _dup(59) "-"
	
	use "$final/ifls-`mount'.dta", clear
	
	* treatment variable
	if "`mount'" == "merapi" {
		drop if treat_ml_120==2
		gen treatment_`mount' = 1 if treat_ml_120 == 1 
		replace treatment_`mount' = 0 if treat_ml_120 == 3 
		}
	if "`mount'" == "kelud" {
		drop if treat_ml_120==1
		gen treatment_`mount' = 1 if treat_ml_120 == 2 
		replace treatment_`mount' = 0 if treat_ml_120 == 3 
	}
	drop if radius_salak_120==1 & radius_galunggung_120==0
	
	* prepping variables for estimation
	g distance=.
	foreach x in merapi kelud galunggung raung {
		replace distance=`x'_distance if radius_`x'_120==1
	}
		
	egen district = group(idprov idkab)
	egen hamlet = group(idprov idkab idkec)

	encode pidlink, gen(pidlinkx)
	
	tempfile `mount'data
	save ``mount'data', replace
	
	* main
	est clear
	eststo reg`mount': bootstrap, rep(1000): areg in_school c.distance##i.year##treatment_`mount' `covariates' latitude longitude , robust cluster(district) absorb(pidlinkx)
	estadd scalar n = e(N)
	estadd scalar r2a =  e(r2_a) 
	
	* robustness 1: distance
	foreach x of numlist 100 80 60 40 {
		di as text _dup(59) "-" ///
		_n as res "distance `x'" ///
		_n as text _dup(59) "-"
		eststo reg`mount'`x': bootstrap, rep(1000): areg in_school c.distance##i.year##treatment_`mount' `covariates' latitude longitude if distance <= `x', robust cluster(district) absorb(pidlinkx)
		estadd scalar n = e(N)
		estadd scalar r2a =  e(r2_a) 
	}
	
	* robustness 2: covariates
	eststo regcov1: bootstrap, rep(1000): reg in_school c.distance##i.year##treatment_`mount' latitude longitude, robust cluster(district) 
	estadd scalar n = e(N)
	estadd scalar r2a =  e(r2_a) 
	
	eststo regcov2: bootstrap, rep(1000): reg in_school c.distance##i.year##treatment_`mount' `covariates'  latitude longitude, robust cluster(district) 
	estadd scalar n = e(N)
	estadd scalar r2a =  e(r2_a) 
	
	eststo regcov3: bootstrap, rep(1000): areg in_school c.distance##i.year##treatment_`mount' `covariates'   latitude longitude, robust cluster(district) absorb(pidlinkx)
	estadd scalar n = e(N)
	estadd scalar r2a =  e(r2_a) 
		
	* heterogeneity
	replace birth_order = 3 if birth_order >= 3
	
	eststo reghet1: bootstrap, rep(1000): areg in_school c.distance##i.year##treatment_`mount'#sex `covariates'  latitude longitude, robust cluster(district) absorb(pidlinkx)
	estadd scalar n = e(N)
	estadd scalar r2a =  e(r2_a) 
	
	eststo reghet2: bootstrap, rep(1000): areg in_school c.distance##i.year##treatment_`mount'#urban `covariates' latitude longitude, robust cluster(district) absorb(pidlinkx)
	estadd scalar n = e(N)
	estadd scalar r2a =  e(r2_a) 
	
	eststo reghet3: bootstrap, rep(1000): areg in_school c.distance##i.year##treatment_`mount'#birth_order `covariates' latitude longitude, robust cluster(district) absorb(pidlinkx)
	estadd scalar n = e(N)
	estadd scalar r2a =  e(r2_a)
	
	* other outcomes
	gen working_not_inschool = isworkinga == 1 &  in_school == 0	
	gen slacking_not_inschool = isworkinga == 0 &  in_school == 0
	
	loc o1 tempabsent
	loc o2 isworkinga
	loc o3 isworkingb
	loc o4 isworkingc
	loc o5 isworkingd
	loc o6 working_not_inschool
	loc o7 slacking_not_inschool
	
	forval i=1/7 {
		eststo reg`i': bootstrap, rep(1000): areg `o`i'' c.distance##i.year##treatment_`mount' `covariates' latitude longitude, robust cluster(district) absorb(pidlinkx)
	}
}

use `merapidata', clear
append using `keluddata'	
		
* Combined Cengiz
egen group_prov = group(estsample idprov)
egen group_district = group(estsample district)
			
g _treated=1 if inlist(1,treatment_merapi,treatment_kelud)
replace _treated=0 if treat_ml_120==3

* Combined regression
eststo regall: bootstrap, rep(1000): areg in_school c.distance##i.year##_treated `covariates' latitude longitude, robust cluster(group_district) absorb(pidlinkx)
estadd scalar n = e(N)
estadd scalar r2a =  e(r2_a) 

log close
