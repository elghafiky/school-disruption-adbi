* ******************************************************************************
* PROGRAM: ADBI
* PROGRAMMER: Elghafiky Bimardhika
* PURPOSE: Multiple period DiD
* DATE CREATED: 29 September 2023
* LATEST MODIFICATION: -
* ******************************************************************************

gl cov age agefather agemother workstat*_*

** KELUD *******************************************************
use "$final/ifls-panel-multiperiod-kelud.dta", clear

* drop irrelevant sample
drop if treat_ml_120==1

* panelize data
duplicates tag pidlink, gen(panel)
qui sum panel
keep if panel==`r(max)'

xtset panelid year 
	
foreach y in 120 100 80 60 {
	* no covariates
	xtreg enrolled treat_kelud_`y'##c.distance i.year latitude longitude, fe cluster(panelid)
	
	* with covariates
	xtreg enrolled treat_kelud_`y'##c.distance $cov i.year latitude longitude, fe cluster(panelid)
} 

** MERAPI CONTROL INCLUDING KELUD (EXCLUDE 2014) *******************************************************
use "$final/ifls-panel-multiperiod-merapi.dta", clear

* drop irrelevant sample
drop if year==2014

* panelize data
duplicates tag pidlink, gen(panel)
qui sum panel
keep if panel==`r(max)'

xtset panelid year 
	
foreach y in 120 100 80 60 {
	* no covariates
	xtreg enrolled treat_merapi_`y'##c.distance i.year latitude longitude, fe cluster(panelid)
	
	* with covariates
	xtreg enrolled treat_merapi_`y'##c.distance $cov i.year latitude longitude, fe cluster(panelid)
} 

** MERAPI CONTROL EXCLUDING KELUD (INCLUDE 2014) *******************************************************
use "$final/ifls-panel-multiperiod-merapi.dta", clear

* drop irrelevant sample
drop if treat_ml_120==2

* panelize data
duplicates tag pidlink, gen(panel)
qui sum panel
keep if panel==`r(max)'

xtset panelid year 
	
foreach y in 120 100 80 60 {
	* no covariates
	xtreg enrolled treat_merapi_`y'##c.distance i.year latitude longitude, fe cluster(panelid)
	
	* with covariates
	xtreg enrolled treat_merapi_`y'##c.distance $cov i.year latitude longitude, fe cluster(panelid)
} 

** MERAPI CONTROL EXCLUDING KELUD & 2014 *******************************************************
use "$final/ifls-panel-multiperiod-merapi.dta", clear

* drop irrelevant sample
drop if treat_ml_120==2|year==2014

* panelize data
duplicates tag pidlink, gen(panel)
qui sum panel
keep if panel==`r(max)'

xtset panelid year 
	
foreach y in 120 100 80 60 {
	* no covariates
	xtreg enrolled treat_merapi_`y'##c.distance i.year latitude longitude, fe cluster(panelid)
	
	* with covariates
	xtreg enrolled treat_merapi_`y'##c.distance $cov i.year latitude longitude, fe cluster(panelid)
} 

** OUTCOME TIME PATH *******************************************************
foreach x in merapi kelud {
	use "$final/`x'-analysis.dta", clear
	if "`x'" == "merapi" local time = 2010
	if "`x'" == "kelud" local time = 2014
	
	keep if year==2014
	drop year
	reshape long enrolled_, i(hhid id) j(year)
	
	* graph
	loc mount=strproper("`x'")
	collapse (mean) enrolled_, by(year treatment_`x')
	twoway connected enrolled_ year if treatment_`x'==0 || connected enrolled_ year if treatment_`x'==1, ///
	ytitle("Enrollment rate") xtitle("") ///
	legend(lab(1 "Control") lab(2 "Treatment") pos(6) row(1)) ylabel(0(0.2)1.0) xlabel(2007(1)2014) xline(`time')
	gr export "$figures/trend-enrollment-`x'.png", replace
	
	export excel year enrolled_ treatment_`x' using "$final/`x'-enrolment-trend.xlsx", replace first(var) nol
}
