* ******************************************************************************
* PROGRAM: PAPER 1
* PROGRAMMER: Lolita Moorena
* PURPOSE: Stacked data analysis
* DATE CREATED: 20 August 2023
* LATEST MODIFICATION: -
* ******************************************************************************

* install command 
// ssc install psmatch2
// ssc install estout

gl cov sex age urban hhsize sex_hhhead  ///
length_schooling_father age_father islam_father jobstat_father_? ///
length_schooling_mother age_mother islam_mother  jobstat_mother_? ///
industry_growth family_card electricity 

** UNMATCHED ***************************************************************
capture log close
est clear
	
log using "$log\analysis_unmatched_main.smcl", replace
foreach mount in "merapi" "kelud" {
	
	loc mp = strupper("`mount'")
	di as text _dup(59) "-" ///
	_n as res "MOUNT `mp'" ///
	_n as text _dup(59) "-"
	
	use "$final/ifls-`mount'.dta", clear
	
	* treatment variable
	if "`mount'" == "merapi" {
		gen treatment_`mount' = 1 if treat_ml_120 == 1 
		replace treatment_`mount' = 0 if treat_ml_120 == 3 
		}
	if "`mount'" == "kelud" {
		gen treatment_`mount' = 1 if treat_ml_120 == 2 
		replace treatment_`mount' = 0 if treat_ml_120 == 3 
	}
	
	* prepping variables for estimation
	g distance=merapi_distance if treat_ml_120==1
	replace distance=kelud_distance if treat_ml_120==2
	replace distance=galunggung_distance if treat_ml_120==3 & galunggung_distance<raung_distance
	replace distance=raung_distance if treat_ml_120==3 & galunggung_distance>raung_distance
		
	egen district = group(idprov idkab)
	egen hamlet = group(idprov idkab idkec)

	encode pidlink, gen(pidlinkx)
	
	save "$final/`mount'-analysis.dta", replace
	
	* main
	eststo reg`mount': bootstrap, rep(1000): areg in_school c.distance##i.year##treatment_`mount' $cov latitude longitude , robust cluster(district) absorb(pidlinkx)
	estadd scalar n = e(N)
	estadd scalar r2a =  e(r2_a)	
}

use "$final/merapi-analysis.dta", clear
append using "$final/kelud-analysis.dta"	
		
* Combined Cengiz
egen group_prov = group(estsample idprov)
egen group_district = group(estsample district)
			
g _treated=1 if inlist(1,treatment_merapi,treatment_kelud)
replace _treated=0 if treat_ml_120==3

save "$final/stacked-analysis.dta", replace

** SUMMARY OF STATISTICS ***************************************************************

la var sex "Male"
la var age "Age"
la var urban "Living in urban area"
la var hhsize "Household size"
la var sex_hhhead "Male household head"
la var length_schooling_father "Years of schooling"
la var age_father "Age"
la var jobstat_father_1 "Self-employer"
la var jobstat_father_2 "Government worker"
la var jobstat_father_3 "Private worker"
la var jobstat_father_4 "Casual worker"
la var jobstat_father_5 "Not working/unpaid worker"
la var length_schooling_mother "Years of schooling"
la var age_mother "Age"
la var jobstat_mother_1 "Self-employer"
la var jobstat_mother_2 "Government worker"
la var jobstat_mother_3 "Private worker"
la var jobstat_mother_4 "Casual worker"
la var jobstat_mother_5 "Not working/unpaid worker"
la var industry_growth "Growth of industry in district"
la var family_card "Have family card"
la var electricity "Have public electricity access"

est clear	
eststo grp1: estpost summ $cov if treatment_merapi == 1 & year == 2007
eststo grp2: estpost summ $cov if treatment_kelud == 1 & year == 2007
eststo grp3: estpost summ $cov if treatment_kelud == 0 & year == 2007
		
esttab grp1 grp2 grp3 using "$tables/summstat.tex" , replace ///
	cells("mean (label(Mean) fmt(2))" ) label modelwidth(28) noobs
esttab grp1 grp2 grp3 using "$tables/summstat.rtf" , replace ///
	cells("mean (label(Mean) fmt(2))" ) label modelwidth(28) noobs	
	
	
* Combined regression ***************************************************************
eststo regall: bootstrap, rep(1000): areg in_school c.distance##i.year##_treated $cov latitude longitude, robust cluster(group_district) absorb(pidlinkx)
estadd scalar n = e(N)
estadd scalar r2a =  e(r2_a) 

esttab regmerapi regkelud regall  using "$tables/table-tripledif-unmatched.tex",  se ar2 ///
star(* 0.10 ** 0.05 *** 0.01)  nonum mtitles("Merapi" "Kelud" "Stacked") ///
modelwidth(20) replace stats(n r2a, labels("Obs." "Adj. R2")) label varwidth(20)	

esttab regmerapi regkelud regall  using "$tables/table-tripledif-unmatched.rtf",  se ar2  ///
star(* 0.10 ** 0.05 *** 0.01)  nonum mtitles("Merapi" "Kelud" "Stacked") ///
modelwidth(20) replace stats(n r2a, labels("Obs." "Adj. R2")) label varwidth(20)	

est clear 
log close

** PSM ***************************************************************	
capture log close
est clear

log using "$log\matching_psm_main.smcl", replace
foreach mount in "merapi" "kelud" {
	use "$final/`mount'-analysis.dta", clear
	
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

	psmatch2 treatment_`mount' $cov if year == 2007 , common
	psgraph 
	gr export "$figures/psgraph-main-`mount'.png", replace
	pstest $cov, scatter outlier treated(_treated) both
	gr export "$figures/pstest-main-`mount'.png", replace

	* check how many are dropped
	tab _treated treatment_`mount' if year == 2007, mis matcell(`mount')

	* fill the treatment value with _treated in 2007	
	bys pidlink (year) : replace _treated = _treated[_n-1] if _treated == . 
	
	* covbal prematching
	foreach x of varlist sex age urban hhsize sex_hhhead  ///
length_schooling_father age_father islam_father jobstat_father_1 jobstat_father_2 jobstat_father_3 jobstat_father_4 jobstat_father_5 ///
length_schooling_mother age_mother islam_mother jobstat_mother_1 jobstat_mother_2 jobstat_mother_3 jobstat_mother_4 jobstat_mother_5 ///
industry_growth family_card electricity {
		areg `x' treatment_`mount' i.year, robust cluster(district) absorb(pidlinkx)
		outreg2 using "$tables\covbal-prematching-`mount'", excel ctitle(`x')
	}
		
	save "$final/`mount'-analysis-psmatch.dta", replace
}

log close
est clear
	
** ESTIMATION WITH PSM ***************************************************************
capture log close
est clear

log using "$log\analysis_psm_main.smcl", replace
foreach mount in "merapi" "kelud" {
	loc mp = strupper("`mount'")
	di as text _dup(59) "-" ///
	_n as res "MOUNT `mp'" ///
	_n as text _dup(59) "-"
		
	use "$final/`mount'-analysis-psmatch.dta", clear
	eststo reg`mount': bootstrap, rep(1000): areg in_school c.distance##i.year##_treated $cov latitude longitude , robust cluster(district) absorb(pidlinkx)
	estadd scalar n = e(N)
	estadd scalar r2a =  e(r2_a) 	
}

* stacked
use "$final/merapi-analysis-psmatch.dta", clear
append using "$final/kelud-analysis-psmatch.dta"

egen group_prov = group(estsample idprov)
egen group_district = group(estsample district)

save "$final/stacked-analysis-psmatch.dta", replace

eststo regall: bootstrap, rep(1000): areg in_school c.distance##i.year##_treated $cov latitude longitude, robust cluster(group_district) absorb(pidlinkx)
estadd scalar n = e(N)
estadd scalar r2a =  e(r2_a) 

esttab regmerapi regkelud regall using "$tables/table-tripledif-psm.tex",  se ar2 ///
star(* 0.10 ** 0.05 *** 0.01) nonum mtitles("Merapi" "Kelud" "Stacked") ///
modelwidth(20) replace stats(n r2a, labels("Obs." "Adj. R2")) label varwidth(20)

esttab regmerapi regkelud regall using "$tables/table-tripledif-psm.rtf",  se ar2 ///
star(* 0.10 ** 0.05 *** 0.01) nonum mtitles("Merapi" "Kelud" "Stacked")  ///
modelwidth(20) replace stats(n r2a, labels("Obs." "Adj. R2")) label varwidth(20)

log close
est clear

** ROBUSTNESS: ENTROPY ***************************************************************
capture log close
est clear

log using "$log\analysis_ebal_main.smcl", replace
foreach mount in "merapi" "kelud" {
	use "$final/`mount'-analysis.dta", clear

	ebalance treatment_`mount' $cov if year==2007, targets(3) gen(e_weights)
	
	* fill the 2014 weight with 2007 weight	
	bys pidlink (year) : replace e_weights = e_weights[_n-1] if e_weights == .

	eststo reg`mount': areg in_school c.distance##i.year##treatment_`mount' $cov latitude longitude [aw=e_weights], robust cluster(district) absorb(pidlinkx)
	estadd scalar n = e(N)
	estadd scalar r2a =  e(r2_a)

	save "$final/`mount'-analysis-ebal.dta", replace
}

* Combined Cengiz
use "$final/merapi-analysis-ebal.dta", clear
append using "$final/kelud-analysis-ebal.dta"
	
egen group_prov = group(estsample idprov)
egen group_district = group(estsample district)

g _treated=1 if treatment_merapi==1|treatment_kelud==1
replace _treated=0 if treat_ml_120==3
	 
save "$final/stacked-analysis-ebal.dta", replace
	
* Combined regression
eststo regall: areg in_school c.distance##i.year##_treated $cov latitude longitude [aw=e_weights], robust cluster(group_district) absorb(pidlinkx)
estadd scalar n = e(N)
estadd scalar r2a =  e(r2_a) 

esttab regmerapi regkelud regall using "$tables/table-tripledif-ebal.tex",  se ar2 ///
star(* 0.10 ** 0.05 *** 0.01) nonum mtitles("Merapi" "Kelud" "Stacked")  ///
modelwidth(20) replace stats(n r2a, labels("Obs." "Adj. R2")) label varwidth(20)

esttab regmerapi regkelud regall using "$tables/table-tripledif-ebal.rtf",  se ar2 ///
star(* 0.10 ** 0.05 *** 0.01) nonum mtitles("Merapi" "Kelud" "Stacked") ///
modelwidth(20) replace stats(n r2a, labels("Obs." "Adj. R2")) label varwidth(20)
		
log close
est clear	

** STACKED COMPARISON ***************************************************************	
capture log close
est clear

* unmatched
use "$final/stacked-analysis.dta", clear
eststo regum: bootstrap, rep(1000): areg in_school c.distance##i.year##_treated $cov latitude longitude, robust cluster(group_district) absorb(pidlinkx)
estadd scalar n = e(N)
estadd scalar r2a =  e(r2_a) 

* psm
use "$final/stacked-analysis-psmatch.dta", clear
eststo regpsm: bootstrap, rep(1000): areg in_school c.distance##i.year##_treated $cov latitude longitude, robust cluster(group_district) absorb(pidlinkx)
estadd scalar n = e(N)
estadd scalar r2a =  e(r2_a) 

* entropy
use "$final/stacked-analysis-ebal.dta", clear
eststo regebal: areg in_school c.distance##i.year##_treated $cov latitude longitude [aw=e_weights], robust cluster(group_district) absorb(pidlinkx)
estadd scalar n = e(N)
estadd scalar r2a =  e(r2_a) 

esttab regum regpsm regebal using "$tables/table-tripledif-stacked.tex",  se ar2  ///
star(* 0.10 ** 0.05 *** 0.01) nonum mtitles("Unmatched" "PSM" "Entropy") ///
modelwidth(20) replace stats(n r2a, labels("Obs." "Adj. R2")) label varwidth(20)

esttab regum regpsm regebal using "$tables/table-tripledif-stacked.rtf",  se ar2  ///
star(* 0.10 ** 0.05 *** 0.01) nonum mtitles("Unmatched" "PSM" "Entropy") ///
modelwidth(20) replace stats(n r2a, labels("Obs." "Adj. R2")) label varwidth(20)	

** ROBUSTNESS: COVARIATES AND DISTANCE ***************************************************************
capture log close
est clear

log using "$log\robustness_cov and dist.smcl", replace

use "$final/stacked-analysis.dta", clear

eststo reg1: bootstrap, rep(1000): reg in_school c.distance##i.year##_treated latitude longitude, robust cluster(group_district) 
estadd scalar n = e(N)
estadd scalar r2a =  e(r2_a) 
	
eststo reg2: bootstrap, rep(1000): reg in_school c.distance##i.year##_treated $cov latitude longitude, robust cluster(group_district) 
estadd scalar n = e(N)
estadd scalar r2a =  e(r2_a) 
	
eststo reg3: bootstrap, rep(1000): areg in_school c.distance##i.year##_treated $cov latitude longitude, robust cluster(group_district) absorb(pidlinkx)
estadd scalar n = e(N)
estadd scalar r2a =  e(r2_a) 

esttab reg1 reg2 reg3 using "$tables/table-robustness-covariates.tex",  se ar2 nomtitle ///
star(* 0.10 ** 0.05 *** 0.01)  ///
modelwidth(20) replace stats(n r2a, labels("Obs." "Adj. R2")) label varwidth(20)

esttab reg1 reg2 reg3 using "$tables/table-robustness-covariates.rtf",  se ar2 nomtitle ///
star(* 0.10 ** 0.05 *** 0.01)  ///
modelwidth(20) replace stats(n r2a, labels("Obs." "Adj. R2")) label varwidth(20)

use "$final/stacked-analysis.dta", clear

foreach mount in merapi kelud {
	use "$final/`mount'-analysis.dta", clear
	
	loc mp = strupper("`mount'")
	di as text _dup(59) "-" ///
	_n as res "MOUNT `mp'" ///
	_n as text _dup(59) "-"
	
	foreach dist of numlist 100 80 60 {
		di as text _dup(59) "-" ///
		_n as res "Distance `dist' KM" ///
		_n as text _dup(59) "-"
		eststo reg`mount'`dist': bootstrap, rep(1500): areg in_school c.distance##i.year##treatment_`mount' $cov latitude longitude if distance <= `dist', robust cluster(district) absorb(pidlinkx)
		estadd scalar n = e(N)
		estadd scalar r2a =  e(r2_a) 	
	}
}

esttab regmerapi100 regmerapi80 regmerapi60 regkelud100 regkelud80 regkelud60 ///
using "$tables/table-robustness-distance.tex",  se ar2 nomtitle ///
star(* 0.10 ** 0.05 *** 0.01)  ///
modelwidth(20) replace stats(n r2a, labels("Obs." "Adj. R2")) label varwidth(20)

esttab regmerapi100 regmerapi80 regmerapi60 regkelud100 regkelud80 regkelud60 ///
using "$tables/table-robustness-distance.rtf",  se ar2 nomtitle ///
star(* 0.10 ** 0.05 *** 0.01)  ///
modelwidth(20) replace stats(n r2a, labels("Obs." "Adj. R2")) label varwidth(20)

log close
est clear

** ROBUSTNESS: ALTERNATE SPECIFICATIONS ***************************************************************
capture log close 
est clear 

log using "$log\alternative specifications.smcl", replace

loc main 	sex age urban sex_hhhead family_card industry_growth

loc pc1 	length_schooling_father age_father islam_father jobstat_father_? ///
			length_schooling_mother age_mother islam_mother jobstat_mother_? 

loc pc2 	length_schooling_hhhead age_hhhead islam_hhhead jobstat_hhhead_?	

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
	
	use "$final/stacked-analysis.dta", clear
	eststo reg`i': bootstrap, rep(1000): areg in_school c.distance##i.year##_treated `cov`i'' latitude longitude, robust cluster(group_district) absorb(pidlinkx)
	estadd scalar n = e(N)
	estadd scalar r2a =  e(r2_a) 	
}

esttab reg1 reg2 reg3 reg4 reg5 reg6 reg7 reg8  ///
using "$tables/table-robustness-altspec.tex",  se ar2 nomtitle ///
star(* 0.10 ** 0.05 *** 0.01)  ///
modelwidth(20) replace stats(n r2a, labels("Obs." "Adj. R2")) label varwidth(20)

esttab reg1 reg2 reg3 reg4 reg5 reg6 reg7 reg8  ///
using "$tables/table-robustness-altspec.rtf",  se ar2 nomtitle ///
star(* 0.10 ** 0.05 *** 0.01)  ///
modelwidth(20) replace stats(n r2a, labels("Obs." "Adj. R2")) label varwidth(20)

log close
est clear
			
** HETEROGENEITY ***************************************************************
capture log close
est clear

log using "$log\heterogeneity.smcl", replace

use "$final/stacked-analysis.dta", clear

replace birth_order = 3 if birth_order >= 3
g edu=edu_2010 if estsample==1
replace edu=edu_2013 if estsample==2

loc h1 sex
loc h2 urban
loc h3 birth_order

forval i=1/3 {
	eststo reg`i': bootstrap, rep(1000): areg in_school c.distance##i.year##_treated#i.`h`i'' $cov  latitude longitude, robust cluster(group_district) absorb(pidlinkx)
	estadd scalar n = e(N)
	estadd scalar r2a =  e(r2_a) 	
}	
	
esttab reg1 reg2 reg3 using "$tables/table-heterogeneity.tex",  se ar2 nomtitle ///
star(* 0.10 ** 0.05 *** 0.01)  ///
modelwidth(20) replace stats(n r2a, labels("Obs." "Adj. R2")) label varwidth(20)	

esttab reg1 reg2 reg3 using "$tables/table-heterogeneity.rtf",  se ar2 nomtitle ///
star(* 0.10 ** 0.05 *** 0.01)  ///
modelwidth(20) replace stats(n r2a, labels("Obs." "Adj. R2")) label varwidth(20)		

log close 
est clear

** OTHER OUTCOMES ***************************************************************
capture log close
est clear 

log using "$log\other outcomes.smcl", replace

use "$final/stacked-analysis.dta", clear	

gen working_not_inschool = isworkinga == 1 &  in_school == 0
replace working_not_inschool = 0 if  in_school == 1
	
gen slacking_not_inschool = isworkinga == 0 &  in_school == 0
replace slacking_not_inschool = 0 if in_school == 1

loc o1 tempabsent
loc o2 isworkinga
loc o3 isworkingb
loc o4 isworkingc
loc o5 isworkingd
loc o6 working_not_inschool
loc o7 slacking_not_inschool
loc o8 failgrade

forval i=1/8 {
	eststo reg`i': bootstrap, rep(1000): areg `o`i'' c.distance##i.year##_treated $cov latitude longitude, robust cluster(group_district) absorb(pidlinkx)
	estadd scalar n = e(N)
	estadd scalar r2a =  e(r2_a) 	
}
				
esttab reg1 reg2 reg3 reg4 reg5 reg6 reg7 reg8 using "$tables/table-otheroutcomes.tex",  se ar2 nomtitle ///
star(* 0.10 ** 0.05 *** 0.01)  ///
modelwidth(20) replace stats(n r2a, labels("Obs." "Adj. R2")) label varwidth(20)

esttab reg1 reg2 reg3 reg4 reg5 reg6 reg7 reg8 using "$tables/table-otheroutcomes.rtf",  se ar2 nomtitle ///
star(* 0.10 ** 0.05 *** 0.01)  ///
modelwidth(20) replace stats(n r2a, labels("Obs." "Adj. R2")) label varwidth(20)

log close 
est clear 

** MECHANISMS ***************************************************************
capture log close
est clear 

log using "$log\mechanisms.smcl", replace
use "$final/stacked-analysis.dta", clear

* Demand
loc m1 road_type_1
loc m2 accessfina
loc m3 accessfinb
loc m4 disaster_assist
loc m5 cash_assist
loc m6 raskin_assist
loc m7 phone_signal_3
loc m8 factory

forval i=1/8 {
	eststo reg`i': bootstrap, rep(1000): areg in_school c.distance##i.year##_treated $cov latitude longitude `m`i'', robust cluster(group_district) absorb(pidlinkx)
	estadd scalar n = e(N)
	estadd scalar r2a =  e(r2_a) 	
}
	
esttab reg1 reg2 reg3 reg4 reg5 reg6 reg7 reg8 using "$tables/table-mechanism-demand.tex",  se ar2 nomtitle ///
star(* 0.10 ** 0.05 *** 0.01)  ///
modelwidth(20) replace stats(n r2a, labels("Obs." "Adj. R2")) label varwidth(20)

esttab reg1 reg2 reg3 reg4 reg5 reg6 reg7 reg8 using "$tables/table-mechanism-demand.rtf",  se ar2 nomtitle ///
star(* 0.10 ** 0.05 *** 0.01)  ///
modelwidth(20) replace stats(n r2a, labels("Obs." "Adj. R2")) label varwidth(20)

est clear
	
* Supply 
egen school = rowtotal(school_1 school_2 school_3)
egen avgpuptchratio=rowmean(pupil*)
foreach x in salary hourteaching hourwork experience {
	egen avgtch`x'=rowmean(*`x'*)
}
	
loc m1 school
loc m2 avgtchsalary
loc m3 avgtchhourteaching
loc m4 avgtchhourwork
loc m5 avgtchexperience
loc m6 avgpuptchratio

forval i=1/6 {
	eststo reg`i': bootstrap, rep(1000): areg in_school c.distance##i.year##_treated $cov latitude longitude `m`i'', robust cluster(group_district) absorb(pidlinkx)
	estadd scalar n = e(N)
	estadd scalar r2a =  e(r2_a) 	
}	

esttab reg1 reg2 reg3 reg4 reg5 reg6 using "$tables/table-mechanism-supply.tex",  se ar2 nomtitle ///
star(* 0.10 ** 0.05 *** 0.01)  ///
modelwidth(20) replace stats(n r2a, labels("Obs." "Adj. R2")) label varwidth(20)

esttab reg1 reg2 reg3 reg4 reg5 reg6 using "$tables/table-mechanism-supply.rtf",  se ar2 nomtitle ///
star(* 0.10 ** 0.05 *** 0.01)  ///
modelwidth(20) replace stats(n r2a, labels("Obs." "Adj. R2")) label varwidth(20)

log close
est clear		

** ROBUSTNESS FOR KELUD: INCLUDING MERAPI ***************************************************************
capture log close
est clear 

log using "$log\keludxmerapi.smcl", replace
use "$input/ifls-panel-all-geocode.dta", clear 

foreach x of numlist 120 100 80 60 {
	foreach z in merapi kelud galunggung raung {
		g radius_`z'_`x'=`z'_distance<=`x'
	}
	g treat_ml_`x'=2 if radius_kelud_`x'==1
	replace treat_ml_`x'=1 if radius_merapi_`x'==1
	replace treat_ml_`x'=3 if radius_galunggung_`x'==1|radius_raung_`x'==1	
	g treat_bi_`x'=1 if inlist(treat_ml_`x',1,2)
	replace treat_bi_`x'=0 if treat_ml_`x'==3
	
	* correcting for regions untreated by kelud 
	replace treat_ml_`x'=. if treat_ml_`x'==2 & inlist(nmkab,"SITUBONDO","BONDOWOSO","JEMBER","BANYUWANGI")
	replace treat_ml_`x'=. if treat_ml_`x'==2 & nmkab=="PASURUAN" & nmkec~="PANDAAN"
	replace treat_ml_`x'=. if treat_ml_`x'==2 & nmkab=="PROBOLINGGO" & idkab<70
	
	replace treat_bi_`x'=. if treat_bi_`x'==1 & inlist(nmkab,"SITUBONDO","BONDOWOSO","JEMBER","BANYUWANGI")
	replace treat_bi_`x'=. if treat_bi_`x'==1 & nmkab=="PASURUAN" & nmkec~="PANDAAN"
	replace treat_bi_`x'=. if treat_bi_`x'==1 & nmkab=="PROBOLINGGO" & idkab<70
}
	
keep if inrange(age,6,19)
keep if enrolled_2013==1
drop if (exclude_sd==1&enrolled_sd_2013==1)|(exclude_smp==1&enrolled_smp_2013==1)|(exclude_sma==1&enrolled_sma_2013==1)
keep if inlist(1,radius_kelud_120,radius_merapi_120,radius_galunggung_120,radius_raung_120) 

duplicates tag pidlink, gen(panel)
drop if panel==0
drop panel

* prepping variables for estimation
gen treatment_kelud = 1 if treat_ml_120<3 
replace treatment_kelud = 0 if treat_ml_120 == 3 

g distance=merapi_distance if treat_ml_120==1
replace distance=kelud_distance if treat_ml_120==2
replace distance=galunggung_distance if treat_ml_120==3 & galunggung_distance<raung_distance
replace distance=raung_distance if treat_ml_120==3 & galunggung_distance>raung_distance
	
egen district = group(idprov idkab)
egen hamlet = group(idprov idkab idkec)
encode pidlink, gen(pidlinkx)

* combine with statistics of industry data
merge m:1 idprov idkab year using "$input/get-industry-statistics.dta"
drop if _m == 2
drop _m
	
eststo keludxmerapi: bootstrap, rep(1000): areg in_school c.distance##i.year##treatment_kelud $cov latitude longitude , robust cluster(district) absorb(pidlinkx)
estadd scalar n = e(N)
estadd scalar r2a =  e(r2_a)	

log close
est clear	
