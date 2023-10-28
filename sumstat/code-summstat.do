* ******************************************************************************
* PROGRAM: ADBI PAPER
* PROGRAMMER: Lolita Moorena
* PURPOSE: FIGURES & SUMMARY OF STATS
* DATE CREATED: 5 September 2023
* LATEST MODIFICATION: -
* ******************************************************************************

* ------------- PODES ------------------* 
use "$raw/2 PODES/PODES 2006/podes06.dta", clear
rename r101b kode_prov
rename r102b kode_kab
rename r103b kode_kec
rename r104b kode_desa
destring r601?k? kode_*, replace
egen sd = rowtotal(r601bk3 r601bk2)
egen smp = rowtotal(r601ck3 r601ck2)
egen sma = rowtotal(r601dk3 r601dk2)
gen year = 2006

keep kode_* sd smp sma year
tempfile 2006
save "`2006'", replace

use "$raw/2 PODES/PODES 2008/podes08.dta", clear
rename prop kode_prov
rename kab kode_kab
rename kec kode_kec
rename desa kode_desa
destring r601?_? kode_*, replace
egen sd = rowtotal(r601b_3 r601b_2)
egen smp = rowtotal(r601c_3 r601c_2)
egen sma = rowtotal(r601d_3 r601d_2)
gen year = 2008

keep kode_* sd smp sma year
tempfile 2008
save "`2008'", replace

use "$raw/2 PODES/PODES 2011/podes_desa_2011_d2.dta", clear
egen sd = rowtotal(r701bk3 r701bk2)
egen smp = rowtotal(r701ck3 r701ck2)
egen sma = rowtotal(r701dk3 r701dk2)
gen year = 2011

keep kode_* sd smp sma year
tempfile 2011
save "`2011'", replace

use "$raw/2 PODES/PODES 2014/podes_desa_2014_d2_new.dta", clear
rename r101 kode_prov
rename r102 kode_kab
rename r103 kode_kec
rename r104 kode_desa
destring kode_*, replace
egen sd = rowtotal(r701b_k3 r701b_k2)
egen smp = rowtotal(r701c_k3 r701c_k2)
egen sma = rowtotal(r701d_k3 r701d_k2)
gen year = 2014

keep kode_* sd smp sma year
tempfile 2014
save "`2014'", replace

use "`2006'",clear
append using "`2008'"
append using "`2011'"
append using "`2014'"

collapse (sum) sd smp sma, by(kode_prov kode_kab kode_kec year)
rename kode_prov idprov
rename kode_kab idkab
rename kode_kec idkec
save "$final/podes-school.dta",replace

use "$input/ifls-panel-sample.dta", clear
collapse (mean) treatment_120, by(idprov idkab idkec )
save"$final/treatment-assignment", replace

merge 1:m idprov idkab idkec using "$final/podes-school.dta"
drop if _m != 3
drop if treatment_120 == . 
collapse (sum) sd smp sma, by(treatment_120 year) 



***** SUMMARY OF STATISTICS
use "$input/ifls-panel-sample.dta", clear


gen treat_1 = 1 if treat_ml_120 == 1
	replace treat_1 = 0 if treat_ml_120 == 3
gen treat_2 = 1 if treat_ml_120 == 2
	replace treat_2 = 0 if treat_ml_120 == 3

la var sex "Male"
la var urban "Live in urban area"
la var hhsize "Household size"
la var sex_hhhead "HH head is Male"
la var lpce "Ln of per capita expenditure"
la var length_schooling_father "Years of schooling"
la var length_schooling_mother "Years of schooling"
la var age "Age"
la var age_father "Age"
la var age_mother "Age"
la var islam_father "Islam"
la var islam_mother "Islam"
la var ethnic1_father "Javanese"
la var ethnic1_mother "Javanese"

local parent father mother
foreach x of local parent {
	la var jobstat_`x'_1 "Self-employed"
	la var jobstat_`x'_2 "Government worker"
	la var jobstat_`x'_3 "Private worker"
	la var jobstat_`x'_4 "Casual worker"
	la var jobstat_`x'_5 "Not employed"
}


local covariates sex age urban hhsize sex_hhhead lpce ///
	length_schooling_father age_father islam_father  jobstat_father_? ///
	length_schooling_mother age_mother  islam_mother    jobstat_mother_? 
	
qui estpost sum `covariates' if treat_ml_120 == 1 & year == 2007
eststo treat_mt1

qui estpost sum `covariates' if treat_ml_120 == 2 & year == 2007
eststo treat_mt2

eststo diff1: qui estpost ttest `covariates' if year == 2007, by(treat_1)
eststo diff2: qui estpost ttest `covariates' if year == 2007, by(treat_2)

esttab treat_mt1 diff1 treat_mt2 diff2 using "$tables/summstat.tex", ///
	mtitle("Mt. Merapi" "Difference" "Mt. Kelud" "Difference") collabels(none) ///
	nonumbers  noobs label ///
	cells("mean(pattern(1 0 1 0) fmt(2)) b(star pattern(0 1 0 1) fmt(2)) ") replace
	
* with stdev
esttab treat_mt1 diff1 treat_mt2 diff2 using "$tables/summstat v2.tex", ///
	mtitle("Mt. Merapi" "Difference" "Mt. Kelud" "Difference") collabels(none) ///
	nonumbers  noobs label ///
	cells("mean(pattern(1 0 1 0) fmt(2)) b(star pattern(0 1 0 1) fmt(2)) " "sd(pattern(1 0 1 0) par)  t(pattern(0 1 0 1) par)") 
