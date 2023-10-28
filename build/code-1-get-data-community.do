* ******************************************************************************
* PROGRAM: PAPER 1
* PROGRAMMER: Lolita Moorena
* PURPOSE: GET ALL IMPORTANT VARIABLES FROM IFLS COMMUNITY LEVEL DATA & STAT INDUSTRI BESAR
* DATE CREATED: 13 April 2023
* LATEST MODIFICATION: 19 August 2023
* ******************************************************************************
	
forval wave = 4/5 {	
	
	if `wave' == 4 {
		
		local wave = 4
		
		local year = "07"
	
******* GET DATA ***************************************************************	

		* Number of schools
		use "${ifls`wave'}/cf`year'dta/bk1_i.dta", clear
			keep itype i13 commid`year'
			reshape wide i13, i(commid`year') j(itype) string
			rename i13A school_1
			rename i13B school_2
			rename i13C school_3
			save "$temp/ifls-`wave'-school.dta", replace

		* Teachers' characteristics
		use "${ifls`wave'}/cf`year'dta/schl.dta", clear
			drop if b2type == "V" | b2type == ""
			replace b2type = "1" if b2type == "A"
			replace b2type = "2" if b2type == "B"
			replace b2type = "3" if b2type == "C"
			gen teacher_salary = c9
			gen teacher_hourteaching = c8a
			gen teacher_hourwork = c8
			gen teacher_experience = c7
			collapse (mean) teacher_salary teacher_hourteaching teacher_hourwork teacher_experience, by(commid`year' b2type)
			reshape wide teacher_salary teacher_hourteaching teacher_hourwork teacher_experience, i(commid`year') j(b2type) string
			save "$temp/ifls-`wave'-teacher.dta", replace
			
		* Pupil-ratio
			* Primary
			use "${ifls`wave'}/cf`year'dta/schl_g1.dta", clear
			collapse (sum) prmtch prmstd, by(commid07)
			gen pupil_teacher1 = prmstd / prmtch
			keep pupil_teacher1 prmstd prmtch commid`year'
			save "$temp/ifls-`wave'-primary.dta", replace
			
			use "${ifls`wave'}/cf`year'dta/schl_g2.dta", clear
			gen smp = 2 if substr(fascode,4,1) == "7"
			replace smp = 3 if smp == .
			collapse (sum) scdtch scdstd, by(commid07 smp)
			reshape wide scdtch scdstd, i(commid07) j(smp) 
			gen pupil_teacher2 = scdstd2 / scdtch2
			gen pupil_teacher3 = scdstd3 / scdtch3
			egen totstd=rowtotal(scdstd*)
			egen tottch=rowtotal(scdtch*)
			keep pupil_teacher2 pupil_teacher3 totstd tottch commid`year'
			save "$temp/ifls-`wave'-jrhg.dta", replace
	
		* Factories
			use "${ifls`wave'}/cf`year'dta/bk1.dta", clear
			rename d28a factory
			recode factory (3=0)
			keep commid`year' factory 
			drop if factory == .
			save "$temp/ifls-`wave'-factory.dta", replace
		
		* Average expenditure per capita
			use "$ifls/pce-1993-1997_2000-2007/pce07nom.dta", clear
			keep commid`year' pce 
			collapse (mean) pce, by(commid`year')
			gen lpce_community = log(pce)
				replace lpce_community = 0.00001 if pce == 0
			keep commid`year' lpce_community 
			save "$temp/ifls-`wave'-pce.dta", replace
			
		* Financial institutions
			use "${ifls`wave'}/cf`year'dta/bk1_g.dta", clear
			g accessfinax=g3a==1 
			g accessfinbx=g3a==1 & (regexm(g3c,"H")|regexm(g3c,"J"))
			bys commid`year': egen accessfina=max(accessfinax)
			bys commid`year': egen accessfinb=max(accessfinbx)
			keep commid`year' accessfina accessfinb
			la var accessfina "Has financial institutions (formal and informal) in the village"
			la var accessfinb "Has access to loans in the village"
			duplicates drop commid`year', force
			save "$temp/ifls-`wave'-fin.dta", replace
			
******* COMBINE ***************************************************************
		* roads
		use "${ifls`wave'}/cf`year'dta/bk1.dta", clear 
		keep commid`year' a8 g6a g6c
		collapse (mean) a8 g6a g6c, by(commid`year')
		drop if a8 == 5 | a8 == .
		tab a8, gen(road_)
		drop a8
		
		* financial institutions
		merge 1:1  commid`year' using "$temp/ifls-`wave'-fin.dta"
			replace accessfina=1 if inlist(1,g6a,g6c)
			replace accessfinb=1 if inlist(1,g6a,g6c)
			keep commid`year' accessfin*
		
		* factories
		merge 1:1 commid`year' using "$temp/ifls-`wave'-factory.dta"
			drop _m
			
		* schools
		merge 1:1 commid`year' using "$temp/ifls-`wave'-school.dta"
		drop _m
		
		* teachers
		merge 1:1 commid`year' using "$temp/ifls-`wave'-teacher.dta"
		drop _m
		
		* pupil student ratio
		merge 1:1 commid`year' using "$temp/ifls-`wave'-primary.dta"
		drop _m
		merge 1:1 commid`year' using "$temp/ifls-`wave'-jrhg.dta"
		drop _m
		replace totstd=totstd+prmstd
		replace tottch=tottch+prmtch
		drop prmstd prmtch
		
		* average per capita expenditure
		merge 1:1 commid`year' using "$temp/ifls-`wave'-pce.dta"
		drop if _m!= 3
		drop _m
		
		gen year = 2007
		save "$input/get-ifls-`wave'-comm.dta", replace
	}
	if `wave' == 5 {
	
		local year = "14"
		
******* GET DATA ***************************************************************	

		* Teachers' characteristics & Pupil-ratio
		use "${ifls`wave'}/cf`year'dta/schl.dta", clear
			gen smp = 1 if substr(fascode,4,1) == "6"
			replace smp = 2 if substr(fascode,4,1) == "7"
			replace smp = 3 if substr(fascode,4,1) == "8"

			gen teacher_salary = c9
			gen teacher_hourteaching = c8a
			gen teacher_hourwork = c8
			gen teacher_experience = c7
			
			collapse (mean) teacher_salary teacher_hourteaching teacher_hourwork teacher_experience (sum) g1atotal g1btotal g2atotal g2btotal, by(commid`year' smp)
			
			reshape wide teacher_salary teacher_hourteaching teacher_hourwork teacher_experience g1atotal g1btotal g2atotal g2btotal, i(commid`year') j(smp) 
			
			gen pupil_teacher1 = g2atotal1 / g1atotal1
			gen pupil_teacher2 = g2btotal2 / g1btotal2
			gen pupil_teacher3 = g2btotal3 / g1btotal3
			egen totstd=rowtotal(g2atotal1 g2btotal2 g2btotal3)
			egen tottch=rowtotal(g1atotal1 g1btotal2 g1btotal3)
			drop g1* g2*
			
			save "$temp/ifls-`wave'-teacher.dta", replace
	
		* Factories
			use "${ifls`wave'}/cf`year'dta/bk1.dta", clear
			rename d28a factory
			recode factory (3=1) (1=0)
			keep commid`year' factory 
			drop if factory == .
			save "$temp/ifls-`wave'-factory.dta", replace
			
		* Average expenditure per capita
			use "$ifls/pce-1993-1997_2000-2007/pce14nom.dta", clear
			keep commid`year' pce 
			collapse (mean) pce, by(commid`year')
			gen lpce_community = log(pce)
				replace lpce_community = 0.00001 if pce == 0
			keep commid`year' lpce_community 
			save "$temp/ifls-`wave'-pce.dta", replace
			
		* Financial institutions
			use "${ifls`wave'}/cf`year'dta/bk1_g.dta", clear
			g accessfinax=g3a==1 
			g accessfinbx=g3a==1 & (regexm(g3c,"H")|regexm(g3c,"J"))
			bys commid`year': egen accessfina=max(accessfinax)
			bys commid`year': egen accessfinb=max(accessfinbx)
			keep commid`year' accessfina accessfinb
			la var accessfina "Has financial institutions (formal and informal) in the village"
			la var accessfinb "Has access to loans in the village"
			duplicates drop commid`year', force
			save "$temp/ifls-`wave'-fin.dta", replace	
			
******* COMBINE ***************************************************************
	
		* roads & schools
		use "${ifls`wave'}/cf`year'dta/bk1.dta", clear 
		keep commid`year' a8 i13_a i13_b i13_c g6a g6c
		collapse (mean) a8 i13_a i13_b i13_c g6a g6c, by(commid`year')
		drop if a8 == 5 | a8 == .
		tab a8, gen(road_)
		drop a8
		
		rename i13_a school_1
		rename i13_b school_2
		rename i13_c school_3
			
		* financial institutions
		merge 1:1  commid`year' using "$temp/ifls-`wave'-fin.dta"
			replace accessfina=1 if inlist(1,g6a,g6c)
			replace accessfinb=1 if inlist(1,g6a,g6c)
			keep commid`year' accessfin*
		
		* factories
		merge 1:1 commid`year' using "$temp/ifls-`wave'-factory.dta"
			drop _m
		
		* teachers & pupil student ratio
		merge 1:1 commid`year' using "$temp/ifls-`wave'-teacher.dta"
		drop _m
		
		* average per capita expenditure
		merge 1:1 commid`year' using "$temp/ifls-`wave'-pce.dta"
		keep if _m == 3
		drop _m
		
		gen year = 2014
		save "$input/get-ifls-`wave'-comm.dta", replace
	}
}

******* STATISTIK INDUSTRI BESAR, SEDANG, & MENENGAH ***************************

use "$raw/5 Statistik Industri/for_fiky.dta", clear
	* fix missing district codes
	bys psid (dprovi dkabup): replace dkabup = dkabup[_n+1] if dkabup == ""
	bys psid (year): gen growth_2007 = (ltlnou / ltlnou[_n-1]) - 1 if year == 2007 & year[_n-1] == 2006
	bys psid (year): gen growth_2014 = (ltlnou / ltlnou[_n-1]) - 1 if year == 2014 & year[_n-1] == 2013
	gen industry_growth = growth_2007	
		replace industry_growth = growth_2014 if industry_growth == .
	keep if inlist(year,2007,2014)
	drop growth_* psid 
	rename ltlnou industry_number 
	rename dprovi idprov 
	rename dkabup idkab
	destring idkab, replace
	collapse (mean) industry_growth industry_number, by(idprov idkab year)
	save "$input/get-industry-statistics.dta", replace
	
