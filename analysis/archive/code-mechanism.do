capture log close
clear all
set more off

log using "$log\mechanism.smcl", replace 

** MECHANISMS *******************************************************
use "$final/ifls-combined-analysis.dta", clear
local covariates sex age urban hhsize sex_hhhead  ///
	length_schooling_father age_father islam_father jobstat_father_? ///
	length_schooling_mother age_mother islam_mother  jobstat_mother_? ///
	industry_growth factory family_card electricity
	
* main
bootstrap, rep(1000): areg in_school c.distance##i.year##_treated `covariates' latitude longitude, robust cluster(group_district) absorb(pidlinkx)

* demand
est clear
foreach x of varlist road_type_1 raskin_assist cash_assist accessfinb {
	eststo `x': bootstrap, rep(1000): areg in_school c.distance##i.year##_treated `covariates' latitude longitude `x', robust cluster(group_district) absorb(pidlinkx)	
	qui estadd scalar n = e(N)
	qui estadd scalar r2a =  e(r2_a) 
	if "`x'"=="road_type_1" {
		outreg2 using "$tables\table-mechanism-demand-fiky", word replace
	}
	else {
		outreg2 using "$tables\table-mechanism-demand-fiky", word	
	}
}

esttab road_type_1 raskin_assist cash_assist accessfinb using "$tables/table-mechanism-demand-fiky.tex",  se ar2 nomtitle ///
star(* 0.10 ** 0.05 *** 0.01)  ///
modelwidth(20) replace stats(n r2a, labels("Obs." "Adj. R2")) label varwidth(20)

* supply
foreach x in hourwork hourteaching salary experience {
	egen teacher_`x'=rowmean(teacher_`x'*)
	if "`x'"=="salary" {
		g ln_teacher_`x'=ln(teacher_`x')
		bootstrap, rep(1000): areg in_school c.distance##i.year##_treated `covariates' latitude longitude ln_teacher_`x', robust cluster(group_district) absorb(pidlinkx)
	}
	else {
		bootstrap, rep(1000): areg in_school c.distance##i.year##_treated `covariates' latitude longitude teacher_`x', robust cluster(group_district) absorb(pidlinkx)
	}
}

g stdtchratio=totstd/tottch
bootstrap, rep(1000): areg in_school c.distance##i.year##_treated `covariates' latitude longitude stdtchratio, robust cluster(group_district) absorb(pidlinkx)

egen school = rowtotal(school_1 school_2 school_3)
g schldensity=totstd/school
bootstrap, rep(1000): areg in_school c.distance##i.year##_treated `covariates' latitude longitude schldensity, robust cluster(group_district) absorb(pidlinkx)

log close 