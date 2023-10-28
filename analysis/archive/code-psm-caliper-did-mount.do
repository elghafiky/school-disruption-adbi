******************************************************************************
* ANALYSIS OF SEPARATE VOLCANOES
******************************************************************************

* install command 
// ssc install psmatch2
// ssc install estout	

** MATCHING ***************************************************************
capture log close
est clear
foreach mount in "merapi" "kelud" {
	use "$final/ifls-`mount'.dta", clear

	if "`mount'" == "merapi" {
		gen treatment_`mount' = 1 if treat_ml_120 == 1 
		replace treatment_`mount' = 0 if treat_ml_120 == 3 
		}
	if "`mount'" == "kelud" {
		gen treatment_`mount' = 1 if treat_ml_120 == 2  
		replace treatment_`mount' = 0 if treat_ml_120 == 3 
	}
	drop if radius_salak_120==1 & radius_galunggung_120==0

	* Matching

	/*
	* good result
	local covariates sex age urban hhsize sex_hhhead lpce ///
		length_schooling_father age_father islam_father  jobstat_father_? ///
		length_schooling_mother age_mother  islam_mother    jobstat_mother_? 
		
	* with podes vars
	local covariates sex age urban hhsize sex_hhhead lpce ///
		length_schooling_father age_father islam_father  jobstat_father_? ///
		length_schooling_mother age_mother  islam_mother    jobstat_mother_? ///
		road_type_? phone_signal_? industry_growth

	* all variables
	market_* school_distance_? hospital_distance transport_? road_type_? central_* phone_signal_? disaster_* hh_PLNelectricity school_? health_staff health_center poor_hh 
		
	age_mother bank electricity ethnic1 factory family_card female have_farm industry_growth industry_number islam_father islam_mother jobstat_father jobstat_mother length_schooling_father length_schooling_mother nonfarm_inc num_dependent num_spouse_hhhead num_school_age_children relig_islam lpce_lag

	community variable
	schools

		electricity ///
		ethnic1 factory family_card have_farm health_staff health_center poor_hh ///
		central_* hh_PLNelectricity transport_?

		have_farm - reduced by 5%
		electricity - reduced by 13%
		ethnic1 - reduced by 13%
		family_card - reduced by 14%
		have_farm - reduced by 14%
		health_staff, poor_hh, central_* - not useful
		
		factory family_card - 0.110
	*/

	local covariates sex age urban hhsize sex_hhhead  ///
	length_schooling_father age_father islam_father jobstat_father_? ///
	length_schooling_mother age_mother islam_mother  jobstat_mother_? ///
	industry_growth family_card electricity

	log using "$log\matching_psmcaliper_`mount'.smcl", replace
	psmatch2 treatment_`mount' `covariates' if year == 2007 , noreplacement caliper(0.1)
	psgraph 
	gr export "$figures/psgraph-psmcaliper-`mount'.png", replace
	pstest `covariates', scatter outlier treated(_treated) both
	gr export "$figures/pstest-psmcaliper-`mount'.png", replace

	* check how many are dropped
	tab _treated treatment_`mount' if year == 2007, mis matcell(`mount')

	* fill the treatment value and weight for 2014
	foreach x of varlist _treated _weight {
		bys pidlink (year) : replace `x' = `x'[_n-1] if `x' == . 	
	}
	
	* tabulate post-matching sample size
	estpost tab _treated
	eststo `mount'
	
	log close

	* prepping variables for estimation
	g distance=.
	foreach x in merapi kelud galunggung raung {
		replace distance=`x'_distance if radius_`x'_120==1
	}
		
	egen district = group(idprov idkab)
	egen hamlet = group(idprov idkab idkec)

	encode pidlink, gen(pidlinkx)
	save "$final/ifls-psmcaliper-`mount'-analysis.dta", replace
}

esttab merapi kelud using "$tables\samplesize_postmatching_psmcaliper.tex", replace noobs nonum ///
title("Post-matching sample size") mtitle("Merapi estimation" "Kelud estimation") nonotes b(%12.0fc)
	
** ESTIMATION ***************************************************************
local covariates sex age urban hhsize sex_hhhead  ///
length_schooling_father age_father islam_father jobstat_father_? ///
length_schooling_mother age_mother islam_mother jobstat_mother_? ///
industry_growth family_card electricity

capture log close
foreach mount in "merapi" "kelud" {
	
	log using "$log\analysis_psmcaliper_`mount'.smcl", replace
	
	* main
	use "$final/ifls-psmcaliper-`mount'-analysis.dta", clear
	eststo reg`mount': bootstrap, rep(1000): areg in_school c.distance##i.year##_treated `covariates' latitude longitude if _weight==1, robust cluster(district) absorb(pidlinkx)
	estadd scalar n = e(N)
	estadd scalar r2a =  e(r2_a) 
	
	* robustness 1: distance
	foreach x of numlist 100 80 60 40 {
		di as text _dup(59) "-" ///
		_n as res "distance `x'" ///
		_n as text _dup(59) "-"
		eststo reg`mount'`x': bootstrap, rep(1000): areg in_school c.distance##i.year##_treated `covariates' latitude longitude if distance <= `x' & _weight==1, robust cluster(district) absorb(pidlinkx)
		estadd scalar n = e(N)
		estadd scalar r2a =  e(r2_a) 
	}
	
	* robustness 2: covariates
	eststo regcov1: bootstrap, rep(1000): reg in_school c.distance##i.year##_treated latitude longitude if _weight==1, robust cluster(district) 
	estadd scalar n = e(N)
	estadd scalar r2a =  e(r2_a) 
	
	eststo regcov2: bootstrap, rep(1000): reg in_school c.distance##i.year##_treated `covariates' latitude longitude if _weight==1, robust cluster(district) 
	estadd scalar n = e(N)
	estadd scalar r2a =  e(r2_a) 
	
	eststo regcov3: bootstrap, rep(1000): areg in_school c.distance##i.year##_treated `covariates' latitude longitude if _weight==1, robust cluster(district) absorb(pidlinkx)
	estadd scalar n = e(N)
	estadd scalar r2a =  e(r2_a) 
		
	* heterogeneity
	replace birth_order = 3 if birth_order >= 3
	
	eststo reghet1: bootstrap, rep(1000): areg in_school c.distance##i.year##_treated#sex `covariates' latitude longitude if _weight==1, robust cluster(district) absorb(pidlinkx)
	estadd scalar n = e(N)
	estadd scalar r2a =  e(r2_a) 
	
	eststo reghet2: bootstrap, rep(1000): areg in_school c.distance##i.year##_treated#urban `covariates' latitude longitude if _weight==1, robust cluster(district) absorb(pidlinkx)
	estadd scalar n = e(N)
	estadd scalar r2a =  e(r2_a) 
	
	eststo reghet3: bootstrap, rep(1000): areg in_school c.distance##i.year##_treated#birth_order `covariates' latitude longitude if _weight==1, robust cluster(district) absorb(pidlinkx)
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
		eststo reg`i': bootstrap, rep(1000): areg `o`i'' c.distance##i.year##_treated `covariates' latitude longitude if _weight==1, robust cluster(district) absorb(pidlinkx)
	}
	
	log close
}
