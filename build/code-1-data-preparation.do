* ******************************************************************************
* PROGRAM: PAPER 1
* PROGRAMMER: Lolita Moorena
* PURPOSE: DATA PREPARATION
* DATE CREATED: 13 April 2023
* LATEST MODIFICATION: -
* ******************************************************************************


*** PWEIGHT
use "$ifls5/hh14dta/ptrack.dta", clear

keep hhid93 hhid97 hhid00 hhid07 hhid14 pidlink pid93 pid97 pid98 pid00 ///
	pid07 pid14 pwt93 pwt97x pwt00xa pwt07xa pwt14xa ///
	pwt_5_waves_lr pwt14la pwt07la pwt00la pwt97l age_07 age_14 bth_month bth_day bth_year

loc ptrackvar pwt_xsection pwt_panel age_07 age_14 bth*
	
save "$temp/pweight.dta", replace

	use "$temp/pweight.dta", clear
	drop if hhid07 == "" | pid07 == .
	duplicates drop hhid07 pid07 pidlink,force
	rename pwt07xa pwt_xsection
	rename pwt07la pwt_panel
	keep hhid07 pid07 `ptrackvar'
	save "$temp/ifls4-weight", replace

	use "$temp/pweight.dta", clear
	drop if hhid14 == "" & pid14 == .
	duplicates drop hhid14 pid14,force
	rename pwt14xa pwt_xsection
	rename pwt14la pwt_panel
	keep hhid14 pid14 `ptrackvar'
	save "$temp/ifls5-weight", replace

*** COMMID & HHID
	use "$ifls4/hh07dta/htrack.dta", clear
	keep hhid07 commid07
	duplicates drop hhid07 commid07, force
	save "$temp/ifls4-hhidcommid", replace
	
	use "$ifls5/hh14dta/htrack.dta", clear
	keep hhid14 commid14
	duplicates drop hhid14 commid14, force
	save "$temp/ifls5-hhidcommid", replace

*** ASSETS - HR
use "$ifls4/hh07dta/b2_hr1.dta", clear
	keep hhid07 hrtype hr01
	reshape wide hr01, i(hhid07) j(hrtype) string
	save "$temp/ifls4-b2_hr1.dta", replace
	
use "$ifls5/hh14dta/b2_hr1.dta", clear
	keep hhid14 hrtype hr01
	reshape wide hr01, i(hhid14) j(hrtype) string
	save "$temp/ifls5-b2_hr1.dta", replace

** Natural Disaster - ND
use "$ifls4/hh07dta/b2_nd2.dta", clear
	g assist = nd16 != "W"
	recode nd18 (3=0)
	local nd nd04 nd05m nd05y assist nd17 nd18
	keep hhid07 ndtype `nd'
	reshape wide `nd', i(hhid07) j(ndtype) string
	save "$temp/ifls4-b2_nd2.dta", replace
	
use "$ifls5/hh14dta/b2_nd2.dta", clear
	g assist = nd16 != "W"
	recode nd18 (3=0)
	local nd nd04 nd05m nd05y assist nd17 nd18
	duplicates drop hhid14 ndtype, force
	keep hhid14 ndtype `nd'
	reshape wide `nd', i(hhid14) j(ndtype) string
	save "$temp/ifls5-b2_nd2.dta", replace
	
* Education for children under 15 yo - DLA	
use "$ifls4/hh07dta/b5_dla2.dta", clear
	local dla dla71a dla71b dla73 dla74a dla75
	keep `dla' hhid* pid* dlatype 
	reshape wide `dla', i(hhid07 pid07) j(dlatype) string
	save "$temp/ifls4-b5_dla2.dta", replace

use "$ifls5/hh14dta/b5_dla2.dta", clear
	local dla dla70 dla71a dla71b dla71f dla73 dla74a dla74c* dla75
	keep `dla' hhid* pid* dlatype 
	reshape wide `dla', i(hhid14 pid14) j(dlatype) 
	save "$temp/ifls5-b5_dla2.dta", replace

use "$ifls4/hh07dta/b5_dla6.dta", clear
	local dla dla56a
	keep `dla' hhid* pid* dla2type
	reshape wide `dla', i(hhid07 pid07) j(dla2type)
	save "$temp/ifls4-b5_dla6.dta", replace

use "$ifls5/hh14dta/b5_dla6.dta", clear
	local dla dla56a
	keep `dla' hhid* pid* dla2type
	reshape wide `dla', i(hhid14 pid14) j(dla2type)
	save "$temp/ifls5-b5_dla6.dta", replace

* Adult education > 15 yo - DL
use "$ifls4/hh07dta/b3a_dl4.dta", clear
	local dl dl10b dl11a dl11b dl13 dl14a* dl15 
	keep `dl' pid* hhid* dl4type
	qui ds dl*, not(varl *Level*)
	reshape wide `r(varlist)', i(hhid07 pid07) j(dl4type)
	save "$temp/ifls4-b3a_dl4.dta", replace

use "$ifls5/hh14dta/b3a_dl4.dta", clear
	local dl dl11a dl11b dl11c dl11f dl13 dl14a* dl14c* dl15
	keep `dl' pid* hhid* dl4type
	drop dl14c3
	qui ds dl*, not(varl *Level*)
	reshape wide `r(varlist)', i(hhid14 pid14) j(dl4type)
	save "$temp/ifls5-b3a_dl4.dta", replace

use "$ifls5/hh14dta/b3a_dl2.dta", clear
	drop if dl2type==.
	local dl dl10 dl11
	keep `dl' pid* hhid* dl2type	
	qui ds dl*, not(varl "*Highest level school attended/or are attending?*")
	reshape wide `r(varlist)', i(hhid14 pid14) j(dl2type)
	save "$temp/ifls5-b3a_dl2.dta", replace	

* Non-farm business
use "$ifls4/hh07dta/b2_nt2.dta", clear
	local nt nt07
	keep `nt' hhid* nt_num 
	qui ds nt*, not(varl "*# bussines*")
	reshape wide `r(varlist)', i(hhid07) j(nt_num)
	save "$temp/ifls4-b2_nt2.dta", replace

use "$ifls5/hh14dta/b2_nt2.dta", clear
	local nt nt07
	keep `nt' hhid* nt_num 
	qui ds nt*, not(varl "*Non-farm business*")
	reshape wide `r(varlist)', i(hhid14) j(nt_num)
	save "$temp/ifls5-b2_nt2.dta", replace

* Social Assistance
use "$ifls4/hh07dta/b1_ksr1.dta", clear
	keep hhid07 ksr3type ksr17
	reshape wide ksr17, i(hhid07) j(ksr3type) string
	gen cash_assist = inlist(1,ksr17A,ksr17B)
	keep hhid07 cash_assist
	save "$temp/ifls4-b1_ksr1.dta", replace
	
use "$ifls5/hh14dta/b1_ksr1.dta", clear
	keep hhid14 ksr3type ksr17
	reshape wide ksr17, i(hhid14) j(ksr3type) string
	gen cash_assist = inlist(1,ksr17A,ksr17B,ksr17C)
	keep hhid14 cash_assist
	save "$temp/ifls5-b1_ksr1.dta", replace

use "$ifls4/hh07dta/b1_ksr2.dta", clear
	keep hhid07 ksr4type ksr24
	reshape wide ksr24, i(hhid07) j(ksr4type) string
	gen raskin_assist = inlist(1,ksr24A,ksr24B)
	keep hhid07 raskin_assist
	merge 1:1 hhid07 using "$temp/ifls4-b1_ksr1.dta"
	drop _m
	save "$temp/ifls4-b1_ksr1.dta", replace
	
use "$ifls5/hh14dta/b1_ksr2.dta", clear
	keep hhid14 ksr24a
	gen raskin_assist = 1
		replace raskin_assist = 0 if ksr24a == "C"
		replace raskin_assist = . if ksr24a == "W"
	keep hhid14 raskin_assist
	merge 1:1 hhid14 using "$temp/ifls5-b1_ksr1.dta"
	drop _m
	save "$temp/ifls5-b1_ksr1.dta", replace
	
* Employment history	
use "$ifls5/hh14dta/b3a_tk3.dta", clear
	local tk tk28 tk33
	keep `tk' hhid* pid* tk28year
	reshape wide `tk', i(hhid14 pid14) j(tk28year)
	save "$temp/ifls5-b3a_tk3.dta", replace

* Migration history
use "$ifls5/hh14dta/b3a_mg2.dta", clear
	keep if mg24yr<2014
	qui levelsof mg24yr
	loc yr `r(levels)'
	duplicates tag hhid14 pid14 mg24yr, gen(dup)
	replace mg34=. if mg34>3
	bys hhid14 pid14 mg24yr: egen movewfam=min(mg34)
	drop if dup>0 & movewfam~=mg34
	bys hhid14 pid14 mg24yr: egen farmove=max(mg27)
	drop if dup>0 & mg27~=farmove
	
	duplicates drop hhid14 pid14 mg24yr, force
	g migrate=1
	
	loc mg mg34 mg36 mg21e mg21d mg21c mg21b mg27 migrate
	keep `mg' hhid14 pid* mg24yr
	reshape wide `mg', i(hhid14 pid14) j(mg24yr)
	
	foreach i of numlist `yr' {
		replace migrate`i'=0 if migrate`i'==.
		labvars mg21e`i' "Country code" ///
				mg21d`i' "Prov code" ///
				mg21c`i' "Kab code" ///
				mg21b`i' "Kec code" ///
				, alternate
	}
	save "$temp/ifls5-b3a_mg2.dta", replace

clear all
