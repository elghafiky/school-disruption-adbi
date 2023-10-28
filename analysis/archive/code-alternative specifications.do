* install command
// ssc install psmatch2

capture log close
log using "$log\alternative specifications.smcl", replace

** ANALYZE DATA ***************************************************************

loc main 	sex age urban sex_hhhead family_card industry_growth

loc pc1 	length_schooling_father age_father islam_father jobstat_father_? ///
			length_schooling_mother age_mother islam_mother jobstat_mother_? 

loc pc2 	length_schooling_hhhead age_hhhead agesq_hhhead jobstat_hhhead_?	

loc hc1 	hhsize 

loc hc2 	num_dependent num_school_age_children

loc ses1 	electricity

loc ses2 	masonry

loc cov1 	`main' `pc1' `hc1' `ses1'
loc cov2 	`main' `pc1' `hc2' `ses1'
loc cov3 	`main' `pc2' `hc1' `ses1'
loc cov4 	`main' `pc2' `hc2' `ses1'
loc cov5 	`main' `pc1' `hc1' `ses2'
loc cov6 	`main' `pc1' `hc2' `ses2'
loc cov7 	`main' `pc2' `hc1' `ses2'
loc cov8 	`main' `pc2' `hc2' `ses2'

forval i=1/8 {
	di as text _dup(59) "-" ///
	_n as res "COVARIATES SET `i'" ///
	_n as text _dup(59) "-" 
	
	foreach mount in "merapi" "kelud" {
	use "$final/ifls-`mount'.dta", clear

	if "`mount'" == "merapi" {
		cap gen treatment_`mount' = 1 if treat_ml_120 == 1 & estsample == 1
		cap replace treatment_`mount' = 0 if treat_ml_120 == 3 & estsample == 1
		}
	if "`mount'" == "kelud" {
		cap gen treatment_`mount' = 1 if treat_ml_120 == 2  & estsample == 2
		cap replace treatment_`mount' = 0 if treat_ml_120 == 3 & estsample == 2
	}
		replace treatment_`mount' = . if treat_ml_120 == .
		
		* 1. PSM		
		psmatch2 treatment_`mount' `cov`i'' if year == 2007 , common
		pstest `cov`i'', scatter outlier treated(_treated) both

		* check how many are dropped
			tab _treated treatment_`mount' if year == 2007, mis matcell(`mount')

		* fill the treatment value with _treated in 2007	
			bys pidlink (year) : replace _treated = _treated[_n-1] if _treated == . 

		* 2. DID
			gen distance = merapi_distance if treat_ml_120 == 1
				replace distance = kelud_distance if treat_ml_120 == 2
				replace distance = galunggung_distance if treat_ml_120 == 3 & galunggung_distance < 120
				replace distance = salak_distance if treat_ml_120 == 3 & distance == . & kelud_distance < 120
				replace distance = raung_distance if treat_ml_120 == 3 & distance == . & raung_distance < 120
				
			egen district = group(idprov idkab)
			egen hamlet = group(idprov idkab idkec)

			encode pidlink, gen(pidlinkx)
			
			bootstrap, rep(1000): areg in_school c.distance##i.year##_treated `cov`i'' latitude longitude , robust cluster(district) absorb(pidlinkx)
			
		tempfile `mount'data
		save ``mount'data', replace
	}

	use `merapidata', clear
	append using `keluddata'	
		
	* Combined Cengiz
		egen group_prov = group(estsample idprov)
		egen group_district = group(estsample district)
			
		* Matching result
		matrix matching_result = merapi \ kelud

		* Combined regression
		bootstrap, rep(1000): areg in_school c.distance##i.year##_treated `cov`i'' latitude longitude, robust cluster(group_district) absorb(pidlinkx)
}

log close
