* ******************************************************************************
* PROGRAM: PAPER 1
* PROGRAMMER: Lolita Moorena
* PURPOSE: COMBINE ALL THE DATA AND ANALYZE USING PSM THEN DID
* DATE CREATED: 20 August 2023
* LATEST MODIFICATION: -
* ******************************************************************************

* install command 
// ssc install cem, replace
// ssc install ebalance, replace

** ANALYZE DATA ***************************************************************

foreach mount in "merapi" "kelud" {
	use "$final/ifls-`mount'.dta", clear
	
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
	
	* 1. CEM and entropy balancing

	local covariates sex age urban hhsize sex_hhhead ///
	length_schooling_father age_father islam_father ///
	jobstat_father_1 jobstat_father_2 jobstat_father_3 jobstat_father_4 jobstat_father_5 ///
	length_schooling_mother age_mother islam_mother ///
	jobstat_mother_1 jobstat_mother_2 jobstat_mother_3 jobstat_mother_4 jobstat_mother_5 ///
	industry_growth family_card electricity 

	cem `covariates' if year==2007, treatment(treatment_`mount')	
	ebalance treatment_`mount' `covariates' if year==2007, targets(3) gen(e_weights)

	* 2. DID
	g distance=.
	foreach x in merapi kelud galunggung raung {
		replace distance=`x'_distance if radius_`x'_120==1
	}
		
	egen district = group(idprov idkab)
	egen hamlet = group(idprov idkab idkec)

	encode pidlink, gen(pidlinkx)
	
	* fill the 2014 weight with 2007 weight	
	bys pidlink (year) : replace e_weights = e_weights[_n-1] if e_weights == .

	eststo reg`mount': areg in_school c.distance##i.year##treatment_`mount' `covariates' latitude longitude [aw=e_weights], robust cluster(district) absorb(pidlinkx)
	estadd scalar n = e(N)
	estadd scalar r2a =  e(r2_a)

	save "$final/ifls-`mount'-analysis_cem-ebal.dta", replace
}

* Combined Cengiz
	use "$final/ifls-merapi-analysis_cem-ebal.dta", clear
	append using  "$final/ifls-kelud-analysis_cem-ebal.dta"
	
	egen group_prov = group(estsample idprov)
	egen group_district = group(estsample district)

	g _treated=1 if treatment_merapi==1|treatment_kelud==1
	replace _treated=0 if treat_ml_120==3
	 
	save "$final/ifls-combined-analysis_cem-ebal.dta", replace
	
	* Combined regression
	eststo regall: areg in_school c.distance##i.year##_treated `covariates' latitude longitude [aw=e_weights], robust cluster(group_district) absorb(pidlinkx)
	estadd scalar n = e(N)
	estadd scalar r2a =  e(r2_a) 
	esttab regmerapi regkelud regall using "$tables/table-tripledif_cem-ebal.tex",  se ar2 nomtitle ///
		star(* 0.10 ** 0.05 *** 0.01)  ///
		modelwidth(20) replace stats(n r2a, labels("Obs." "Adj. R2")) label varwidth(20)	
