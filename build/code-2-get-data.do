* ******************************************************************************
* PROGRAM: PAPER 1
* PROGRAMMER: Lolita Moorena
* PURPOSE: GET ALL IMPORTANT VARIABLES
* DATE CREATED: 13 April 2023
* LATEST MODIFICATION: -
* ******************************************************************************
capture log close 
clear all
set more off

loc y4 = "07"
loc y5 = "14"

log using "$log\get data.smcl", replace

forval i =4/5 {
	dis as res "=======IFLS`i'======="

	use "${ifls`i'}/hh`y`i''dta/bk_ar1.dta", clear	
	local var01 hhid* pid* ar00 ar01a ar02b ar07 ar08* ar09 ar10-ar14 ar15 ar15a ar15d ar16 ar17 ar18c
	keep `var01'
	
	dis as res "merge SC book"
	if `i'==5 {
		merge m:1 hhid`y`i'' using "${ifls`i'}/hh`y`i''dta/bk_sc1.dta"		
	}
	else {
		merge m:1 hhid`y`i'' using "${ifls`i'}/hh`y`i''dta/bk_sc.dta"
	}	
	drop if _merge==2
	local var02 `var01' sc01* sc02* sc03* sc05
	keep `var02'
		 
	dis as res "merge weighting dataset"	 
	merge 1:1 hhid`y`i'' pid`y`i'' using "$temp/ifls`i'-weight.dta"
	drop if _merge==2
	loc var03 `var02' pwt_xsection pwt_panel age_07 age_14 bth*
	keep `var03'
		
	dis as res "merge pce dataset"
	merge m:1 hhid`y`i'' using "$ifls/pce-1993-1997_2000-2007/pce`y`i''nom.dta"
	drop if _merge==2
	loc var04 `var03' pce
	keep `var04' 
		
	dis as res "merge UT book"
	merge m:1 hhid`y`i'' using "${ifls`i'}//hh`y`i''dta/b2_ut1.dta"
	drop if _merge==2
	loc var05 `var04' ut00a ut00bh ut00bm ut00bx ut07
	keep `var05'
		
	dis as res "merge KR book"	
	merge m:1 hhid`y`i'' using "${ifls`i'}//hh`y`i''dta/b2_kr.dta"
	drop if _merge==2
	local var06 `var05' kr11 kr24a kr27?
	keep `var06' 
	
	dis as res "merge HR book"	
	merge m:1 hhid`y`i'' using "$temp/ifls`i'-b2_hr1.dta"
	drop if _merge==2
	loc var07 `var06' hr01*
	keep `var07' 
		
	dis as res "merge ND1 book"	
	merge m:1 hhid`y`i'' using "${ifls`i'}/hh`y`i''dta/b2_nd1.dta"
	drop if _merge==2
	loc var08 `var07' nd01 nd02
	keep `var08'

	dis as res "merge ND2 book"
	merge m:1 hhid`y`i'' using "$temp/ifls`i'-b2_nd2.dta"
	drop if _merge==2
	drop _merge

	dis as res "merge NT book"
	merge m:1 hhid`y`i'' using "$temp/ifls`i'-b2_nt2.dta"
	drop if _merge==2
	drop _merge
	qui ds
	loc var09 `r(varlist)'

	dis as res "merge TK1 book"
	merge 1:1 hhid`y`i'' pid`y`i'' using "${ifls`i'}//hh`y`i''dta/b3a_tk1.dta"
	drop if _merge==2
	loc var10 `var09' tk05
	keep `var10'

	dis as res "merge TK2 book"
	merge 1:1 hhid`y`i'' pid`y`i'' using "${ifls`i'}//hh`y`i''dta/b3a_tk2.dta"
	drop if _merge==2
	loc var11 `var10' tk24a
	keep `var11'

	dis as res "merge DLA2 book"
	merge 1:1 hhid`y`i'' pid`y`i'' using "$temp/ifls`i'-b5_dla2.dta"
	drop if _merge==2
	drop _merge

	dis as res "merge DLA6 book"
	merge 1:1 hhid`y`i'' pid`y`i'' using "$temp/ifls`i'-b5_dla6.dta"
	drop if _merge==2
	drop _merge

	dis as res "merge DL4 book"
	merge 1:1 hhid`y`i'' pid`y`i'' using "$temp/ifls`i'-b3a_dl4.dta"
	drop if _merge==2
	drop _merge

	dis as res "merge KRK book"
	qui ds
	loc var12 `r(varlist)'
	merge m:1 hhid`y`i'' using "${ifls`i'}//hh`y`i''dta/bk_krk.dta"
	drop if _merge==2
	loc var13 `var12' krk09 krk10
	keep `var13'
	
/*
	dis as res "merge BH book"
	merge m:1 hhid`y`i'' using "${ifls`i'}//hh`y`i''dta/b2_bh.dta"
	drop if _merge==2
	drop _merge
*/
	dis as res "merge KSR book"
	merge m:1 hhid`y`i'' using "$temp/ifls`i'-b1_ksr1.dta"
	drop if _merge==2
	drop _merge
	
	if `i'==5 {
		dis as res "merge DL2 book"
		merge 1:1 hhid14 pid14 using "$temp/ifls5-b3a_dl2.dta"
		drop if _merge==2
		drop _merge

		dis as res "merge MAA book"
		qui ds
		loc var14 `r(varlist)'
		merge 1:1 hhid14 pid14 using "$ifls5//hh14dta/b5_maa1.dta"
		drop if _merge==2
		loc var15 `var14' maa06
		keep `var15'
		
		dis as res "merge TK3 book"
		merge 1:1 hhid14 pid14 using "$temp/ifls5-b3a_tk3.dta"
		drop if _merge==2
		drop _merge
		
		dis as res "merge MG1 book"
		qui ds
		loc var16 `r(varlist)'
		merge 1:1 hhid14 pid14 using "$ifls5//hh14dta/b3a_mg1.dta"
		drop if _merge==2
		foreach x in mg01 mg03b mg05 mg07 {
			ren `x'd `x'prov
			ren `x'c `x'kab
			ren `x'b `x'kec
		}
		
		foreach x in prov kab kec {
			clonevar `x'ori=mg01`x'
			replace `x'ori=mg03b`x' if mg03b`x'<. 
			replace `x'ori=mg05`x' if mg04a==3
			replace `x'ori=mg07`x' if mg07`x'<.
		}

		loc var17 `var16' provori kabori kecori mg00x
		keep `var17'
			
		dis as res "merge MG2 book"
		merge 1:1 hhid14 pid14 using "$temp/ifls5-b3a_mg2.dta"
		drop if _merge==2
		drop _merge
	}
	else {
		drop hhid14
	}

	dis as res "merge commid book"	
	merge m:1 hhid`y`i'' using "$temp/ifls`i'-hhidcommid"
	drop if _merge==2
	drop _merge
				
	gen year = "20`y`i''"
	destring year, replace 

	save "$input/get-ifls-`i'.dta", replace
}	

log close 
