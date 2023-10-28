* ******************************************************************************
* PROGRAM: PAPER 1
* PROGRAMMER: Lolita Moorena
* PURPOSE: RENAME AND RECODE ALL IMPORTANT VARIABLES
* DATE CREATED: 13 April 2023
* LATEST MODIFICATION: -
* ******************************************************************************

* ==== INDIVIDUAL-LEVEL DATA ==== *

* Append all data
use "$input/get-ifls-4.dta",clear
append using "$input/get-ifls-5.dta"

* drop individual no longer in the household
drop if inlist(ar01a,0,3)  // as suggested in ifls user guide
	
g hhid=hhid07 if year==2007
replace hhid=hhid14 if year==2014

g id=pid07 if year==2007
replace id=pid14 if year==2014

* SC section
	clonevar provid14=sc01
	clonevar kabid14=sc02
	clonevar kecid14=sc03

	merge m:1 provid14 kabid14 kecid14 using "$ifls/IFLS5_BPS_2014_codes/bps2014.dta", gen(m_bps2014)
	drop if m_bps2014==2
	drop m_bps2014

	clonevar provid07=sc010707 
	clonevar kabid07=sc020707 
	clonevar kecid07=sc030707 

	tempfile scsec
	save `scsec', replace

	import excel "$ifls/IFLS4_BPS_2007_codes/2007 provid.xlsx", clear first	
	save "$ifls/IFLS4_BPS_2007_codes/2007 provid.dta", replace 

	import excel "$ifls/IFLS4_BPS_2007_codes/2007 BPS Codes v2.xlsx", clear first
	rename Table41IndonesianKecamatanC A

	foreach x of varlist _all {
		replace `x'=strtrim(`x')
		drop if inlist(`x',"PROVINCE","KABUPATEN","KECAMATAN","Code","Name")
	}

	drop if A==""

	destring A, force replace
	drop if A==.

	ren (A B C D E) (provid07 kabid07 kabnm07 kecid07 kecnm07)
	merge m:1 provid07 using "$ifls/IFLS4_BPS_2007_codes/2007 provid.dta"
	drop _merge
	order provnm07, after(provid07)
	replace provnm07="PAPUA" if provnm07=="tPAPUA"
	replace kabid07="1" if inlist(kecnm07,"KEPULAUAN SERIBU SELATAN","KEPULAUAN SERIBU UTARA")
	destring kabid07 kecid07, replace

	save "$ifls/IFLS4_BPS_2007_codes/2007 BPS Codes clean.dta", replace

	merge 1:m provid07 kabid07 kecid07 using `scsec', gen(m_bps2007) 
	drop if m_bps2007==1
	drop m_bps2007

	foreach x in prov kab kec {
		foreach y in nm id {
			g `y'`x'=`x'`y'14
			if "`y'"=="nm" {
				replace `y'`x'=`x'`y'07 if `y'`x'==""
			}
			if "`y'"=="id" {
				replace `y'`x'=`x'`y'07 if `y'`x'==.	
			}
		}
		replace nm`x'=strtrim(nm`x')
	}
	replace nmprov="DI YOGYAKARTA" if nmprov=="D I YOGYAKARTA"
	replace nmprov="KALIMANTAN SELATAN" if nmprov=="KALIMANTAN  SELATAN"
	replace nmprov="KALIMANTAN TENGAH" if nmprov=="KALIMANTAN  TENGAH"
	replace nmprov="KEPULAUAN BANGKA BELITUNG" if nmprov=="KEPULAUAN BANGKA DAN BELITUNG"
	replace nmkab="BATAM" if nmkab=="B A T A M"
	replace nmkab="DUMAI" if nmkab=="D U M A I"
	replace nmkab="SIAK" if nmkab=="S I A K"

	gen byte urban = sc05 == 1
	
	preserve
	keep hhid id pidlink year prov* kab* kec* mg* migrate*
	save "$input/ifls-migration.dta", replace 
	restore
	drop mg* migrate* *ori

* AR section
	rename ar00 membernumber
	gen byte rel_head = ar02b
		replace rel_head = . if rel_head > 17
	gen byte female = ar07 == 3
	ren (ar08day ar08mth ar08yr ar09) (birth_date birth_month birth_year age)
	replace age=. if inlist(age,998,999)
	foreach x of varlist birth_date birth_month {
		replace `x'=. if inlist(`x',98,99)
	}
	replace birth_year=. if inlist(birth_year,9998,9999)
	egen DOB=concat(birth_year birth_month birth_date)
	replace DOB=subinstr(DOB,".","",.)

	gen byte marital = ar13
		replace marital = . if marital > 6 
	* 5 labels: unmarried, married, separated, divorced, widow
	* in ifls 5, it's 6 labels : unmarried, married, separated, divorced, widow, cohabitate
	gen byte relig_islam = ar15 == 1
		replace relig_islam = . if ar15 > 90
		la var relig_islam "Islam"
	gen byte relig_excislam = ar15 != 1
		replace relig_excislam = . if ar15 > 90
		la var relig_excislam "Non-Islam"
		* 6 labels: islam, protestan, catholic, hindu, buddhism, confucians
	
	* Only IFLS 5 has ethnicity
		gen byte ethnic1 = ar15d == 1
			la var ethnic1 "Javanese"
		gen byte ethnic2 = ar15d == 2
			la var ethnic2 "Sundanese"
		gen byte ethnic3 = ar15d == 9
			la var ethnic3 "Minang"
		gen byte ethnic4 = ar15d == 4
			la var ethnic4 "Batak"
		gen byte ethnic5 = ar15d == 8
			la var ethnic5 "Sasak"
		gen byte ethnic6 = ar15d == 3
			la var ethnic6 "Balinese"
		gen byte ethnic7 = inlist(ar15d,5,6,7) | ar15d > 9
			la var ethnic7 "Others"
		forval i = 1/7 {
			replace ethnic`i' = . if ar15d > 90
		}
	
	rename ar10 father_id
	rename ar11 mother_id
	rename ar12 carer_id
	rename ar14 spouse_id	
	
	gen edu_attend = ar16
		replace edu_attend = 0 if edu_attend == 90
		replace edu_attend = 1 if inlist(edu_attend,2,11,72)
		replace edu_attend = 2 if inlist(edu_attend,3,12,73,4)
		replace edu_attend = 3 if inlist(edu_attend,5,15,74,6)
		replace edu_attend = 4 if inlist(edu_attend,60,61,62,63,13,7,8,9)
		replace edu_attend = . if inlist(edu_attend,14,17,70,10)
	gen edu_completed = ar17
		replace edu_completed = 0 if edu_completed == 90
		replace edu_completed = 1 if inlist(edu_completed,2,11,72)
		replace edu_completed = 2 if inlist(edu_completed,3,12,73,4)
		replace edu_completed = 3 if inlist(edu_completed,5,15,74,6)
		replace edu_completed = 4 if inlist(edu_completed,60,61,62,63,13,7,8,9)
		replace edu_completed = . if inlist(edu_completed,14,17,70,10)				
	gen byte in_school = ar18c
		replace in_school = . if in_school > 3
		replace in_school = 0 if in_school == 3

	* sex
	rename ar07 sex
	replace sex=0 if sex==3

	* number of school-aged children
	g school_age=inrange(age,6,18)
	bys hhid: egen num_school_age_children=total(school_age)

	* number of dependent
	g dependent=age<=6 | age>65
	bys hhid: egen num_dependent=total(dependent)
	
	* household size
	bys hhid: g hhsize=_N

	* age
	ren birth_date birth_day
	g slash1="/"
	g slash2="/"

	g daysto_new_acyear_2010=date("2010/7/12","YMD")
	g daysto_new_acyear_2013=date("2013/7/15","YMD")

	foreach x in bth birth {
		replace `x'_year=. if inlist(`x'_year,9998,9999)
		foreach y in month day {
			replace `x'_`y'=. if inlist(`x'_`y',98,99)
		}
		egen `x'_date_ymd=concat(`x'_year slash1 `x'_month slash2 `x'_day) if `x'_year<. & `x'_month<. & `x'_day<.
		egen `x'_date_ym=concat(`x'_year slash1 `x'_month) if `x'_year<. & `x'_month<. & `x'_day==.

		g daysto_`x'_ymd=date(`x'_date_ymd,"YMD")
		g daysto_`x'_ym=date(`x'_date_ym,"YM")
		
		foreach y of numlist 2010 2013 {
			g age_`x'_`y'_ymd=(daysto_new_acyear_`y'-daysto_`x'_ymd)/365
			g age_`x'_`y'_ym=(daysto_new_acyear_`y'-daysto_`x'_ym)/365
		}
	}

	foreach x of numlist 2010 2013 {
		g age_`x'=age_bth_`x'_ymd if year==2014
		replace age_`x'=age_birth_`x'_ymd if age_`x'==. & year==2014
		replace age_`x'=age_bth_`x'_ym if age_`x'==. & year==2014
		replace age_`x'=age_birth_`x'_ym if age_`x'==. & year==2014
		if `x'==2010 {
			replace age_2010=age_14-4 if age_2010==. & year==2014
			replace age_2010=age_07+3 if age_2010==. & year==2014
			replace age_2010=age-4 if age_2010==. & year==2014	
		}
		else if `x'==2013 {			
			replace age_2013=age_14-1 if age_2013==. & year==2014
			replace age_2013=age_07+6 if age_2013==. & year==2014
			replace age_2013=age-1 if age_2013==. & year==2014	
		}
		bys pidlink (year) : replace age_`x' = age_`x'[_n+1] if year == 2007 
	}
	drop slash* age_b* daysto*
	
	replace age=age_07 if year==2007 & age_07<.
	replace age=age_14 if year==2014 & age_14<.
	replace age=age_2010+4 if age==. & year==2014
	replace age=age_2010-3 if age==. & year==2007
	replace age=age_2013+1 if age==. & year==2014
	replace age=age_2013-6 if age==. & year==2007
	
	ren (age_07 age_14 age_2010 age_2013) (age2007 age2014 age_byac_2010 age_byac_2013)
	foreach x of numlist 2007 2014 {
		replace age`x'=age if year==`x' & age`x'==.
	}
	bys pidlink (year) : replace age2007 = age2007[_n-1] if year == 2014 & age2007==.
	bys pidlink (year) : replace age2014 = age2014[_n+1] if year == 2007 & age2014==.
	
	forval i=2008/2013 {
		g age`i'=age2014-(2014-`i')
	}
	replace age2007=age2014-7 if age2007==.

	* age-appropiateness
	g age_appropiate_sd=inrange(age,7,12)
	g age_appropiate_smp=inrange(age,13,15)
	g age_appropiate_sma=inrange(age,16,18) 

	* birth order
	bys hhid07 (age) : gen birth_order = _n if age != . & age <= 12 
	replace birth_order = . if hhid07 == ""
	bys pidlink (year) : replace birth_order = birth_order[_n-1] if year == 2014 

	* work/not work
	g isworkinga=ar15a==1
	replace isworkinga=. if inlist(ar15a,6,8,9)
	g isworkingb=dla56a1==1|dla56a2==1|dla56a3==1|tk05==1
	g isworkingc=dl151==1|dl152==1|dl153==1|dla751==1|dla752==1|dla753==1
	g isworkingd=isworkinga==1|isworkingb==1|isworkingc==1

	* length of schooling

	* no schooling (highest level attended kindergarten = no schooling)
	g length_schooling=0 if inlist(ar16,1,90)  

	* primary school (did not finish first grade = 1 year)
	* assume pesantren and slb is primary level
	replace length_schooling=1 if inlist(ar16,2,11,72,14,17) & inrange(ar17,0,1)
	forval i =2/5 {
		replace length_schooling=`i' if inlist(ar16,2,11,72,14,17) & ar17==`i'
	}
	replace length_schooling=6 if inlist(ar16,2,11,72,14,17) & inrange(ar17,6,7)

	* junior high (did not finish first grade = 7 year)
	replace length_schooling=7 if inlist(ar16,3,4,12,73) & inrange(ar17,0,1)
	replace length_schooling=8 if inlist(ar16,3,4,12,73) & ar17==2
	replace length_schooling=9 if inlist(ar16,3,4,12,73) & inlist(ar17,3,7)

	* senior high (did not finish first grade = 10 year)
	replace length_schooling=10 if inlist(ar16,5,6,15,74) & inrange(ar17,0,1)
	replace length_schooling=11 if inlist(ar16,5,6,15,74) & ar17==2
	replace length_schooling=12 if inlist(ar16,5,6,15,74) & inlist(ar17,3,7)

	* university 
	* did not finish first grade = 13 year
	* bachelor degree assumed to never take diploma previously
	* grade>4 = grade=4 for uni
	* grade>3 = grade=3 for uni
	replace length_schooling=13 if inlist(ar16,13,60,61) & inrange(ar17,0,1)
	forval i =2/4 {
		replace length_schooling=`i'+12 if inlist(ar16,13,61) & ar17==`i'
	}
	forval i =2/3 {
		replace length_schooling=`i'+12 if ar16==60 & ar17==`i'
	}
	replace length_schooling=16 if inlist(ar16,13,61) & inrange(ar17,5,7)
	replace length_schooling=15 if ar16==60 & inrange(ar17,4,7)

	* master (grade>3 = grade=2)
	replace length_schooling=17 if ar16==62 & inrange(ar17,0,1)
	replace length_schooling=18 if ar16==62 & inrange(ar17,2,7)

	* doctoral 
	* all assumed to have completed master first
	* grade>4 = grade=4
	replace length_schooling=19 if ar16==63 & inrange(ar17,0,1)
	forval i = 2/3 {
		replace length_schooling=`i'+18 if ar16==63 & ar17==`i'
	}
	replace length_schooling=22 if ar16==63 & inrange(ar17,4,7)	
		
	* for the remaining missing values:
	* year of schooling = grade for grade 1-6 (for those with uncommon school type)
	* year of schooling = 1 if grade==0 (did not finish first year)
	* year of schooling = mean if grade==7 (graduated) 
	replace length_schooling=ar17 if length_schooling==. & inrange(ar17,1,6)  
	replace length_schooling=1 if length_schooling==. & ar17==0  
	qui sum length_schooling
	replace length_schooling=floor(`r(mean)') if length_schooling==. & ar17==7   

	* if there are still remaining missing values (for those who doesn't know the grade)
	* year of schooling = mean year of schooling of the education level
	* primary
	qui sum length_schooling if inlist(ar16,2,11,72,14,17) 
	replace length_schooling=floor(`r(mean)') if length_schooling==. & inlist(ar16,2,11,72,14,17)

	* junior
	qui sum length_schooling if inlist(ar16,3,4,12,73) 
	replace length_schooling=floor(`r(mean)') if length_schooling==. & inlist(ar16,3,4,12,73)

	* senior
	qui sum length_schooling if inlist(ar16,5,6,15,74) 
	replace length_schooling=floor(`r(mean)') if length_schooling==. & inlist(ar16,5,6,15,74)
	
	* uni
	qui sum length_schooling if inlist(ar16,13,61) 
	replace length_schooling=floor(`r(mean)') if length_schooling==. & inlist(ar16,13,61)

	* diploma
	qui sum length_schooling if ar16==60 
	replace length_schooling=floor(`r(mean)') if length_schooling==. & ar16==60

	* master
	qui sum length_schooling if ar16==62 
	replace length_schooling=floor(`r(mean)') if length_schooling==. & ar16==62

	* doctoral
	qui sum length_schooling if ar16==63 
	replace length_schooling=floor(`r(mean)') if length_schooling==. & ar16==63

	* don't know the grade and level
	qui sum length_schooling
	replace length_schooling=floor(`r(mean)') if length_schooling==. & ar17==98

* UT & NT section
	gen byte have_farm = ut00a == 1
		replace have_farm = . if ut00a == 9
	gen area_farm = ut00bh * 10000 if ut00bx == 1
		replace area_farm = ut00bm if ut00bx == 1
	egen nonfarm_inc=rowtotal(nt071 nt072)
	egen biz_inc=rowtotal(nonfarm_inc ut07)
	foreach x of varlist nonfarm_inc biz_inc {
		replace `x'=0 if `x'==.
	}
	g nonfarm_inc_share=nonfarm_inc/biz_inc	
	replace nonfarm_inc_share=0 if nonfarm_inc_share==.

* KR section
	gen byte electricity = kr11 == 1
	gen byte social_assistance = inlist(1,kr27a, kr27b,kr27d,kr27e,kr27f,kr27g,kr27h,kr27i)
	gen byte tv = kr24a == 1
	gen byte family_card = kr27k == 1

* KRK section
	g masonry=krk09==1	

* HR section
	local alph A B C D1 D2 D3 E F G H J K1 K2
	foreach var of local alph{
		replace hr01`var' = 0 if hr01`var' == 3
	}

* ND section
	// foreach x in A B C D E F G H I J S {
	// 	g nd01`x'=regexm(nd01,"`x'")		
	// }	

	// gen byte merapi = nd01D == 1 & inlist(nd05yD,2010,2011) & inlist(nmprov,"DI YOGYAKARTA","JAWA TENGAH")
	// 	replace merapi = 1 if nd01E == 1 & inlist(nd05yE,2010,2011) & inlist(nmprov,"DI YOGYAKARTA","JAWA TENGAH") 	
	g disaster_assist = assistD==1|assistE==1
	egen disaster_assist_amt=rowtotal(nd17D nd17E)
	g disaster_temphouse = nd18D==1|nd18E==1
		
/*
	* BH section
	g loan_know = bh00 == 1
		replace loan_know = . if bh00 == .
	g loan_secure = bh07 == 1
		replace loan_secure = . if bh07 == .
*/

	* MAA section
	g nomorbidity=regexm(maa06,"W")
	replace nomorbidity=. if maa06=="" 
	bys pidlink (year) : replace nomorbidity = nomorbidity[_n+1] if year == 2007 

	* DL & DLA section

	* temporary absenteism and grade failure outcome
	loc s1 "sd"
	loc s2 "smp"
	loc s3 "sma"

	forval i=1/3 {
		g failgrade_`s`i''= dl13`i'==1|dla73`i'==1
		g tempabsent_`s`i''= dl14a`i'==1|dla74a`i'==1
	}
	foreach x in failgrade tempabsent {
		g `x'=`x'_sd==1|`x'_smp==1|`x'_sma==1
	}

	* construct variable to indicate if has graduated SMA in 2014
	g graduated_hs_2014=dl11c3==7 & year==2014

	* change outcome status to enrolled if graduated hs in 2014
	replace in_school=1 if graduated_hs_2014==1

	* continuing to tertiary education in 2011-2014
	g continue_tertiary=inrange(dl11a4,2011,2015)

	// * indicate observations which enrolled in SD at 6 years old after 2003
	// foreach x of varlist dla71a* dl11a* dla71b* dl11b* dl10b* dl111-dl113 {
	// 	replace `x'=. if inlist(`x',98,99,9998,9999)
	// }
	// foreach x in dla71 dl11 {
	// 	replace `x'b1=year-`x'a1 if `x'b1==.
	// }
	// g enroll_sd_6yo_post2003=1 if ((dla71a1>2003 & dla71a1<.)|(dl11a1>2003 & dl11a1<.)) & (dla71b1==6|dl11b1==6)
	// replace enroll_sd_6yo_post2003=0 if ((dla71a1>2003 & dla71a1<.)|(dl11a1>2003 & dl11a1<.)) & ((dla71b1>6 & dla71b1<.)|(dl11b1>6 & dl11b1<.))

	// g public_school=1 if dl10b1<3|dl111<3
	// replace public_school=0 if (dl10b1>2&dl10b1<.)|(dl111>2&dl111<.)

	* TK section
	la def jstat 	1 "1 Self-employed" ///
					2 "2 Government worker" ///
					3 "3 Private worker" ///
					4 "4 Casual worker" ///
					5 "5 Not working/unpaid worker" 
					
	g jobstat=5
	replace jobstat=1 if inrange(tk24a,1,3)
	replace jobstat=2 if tk24a==4
	replace jobstat=3 if tk24a==5
	replace jobstat=4 if inrange(tk24a,7,8)
	replace jobstat=. if tk24a==9

	forval i=2007/2014 {
		g workstat`i'=5 if tk28`i'==3
		replace workstat`i'=1 if inrange(tk33`i',1,3)
		replace workstat`i'=2 if tk33`i'==4
		replace workstat`i'=3 if tk33`i'==5
		replace workstat`i'=4 if inrange(tk33`i',7,8)
		replace workstat`i'=. if tk33`i'==9
	}
	
	la val jobstat workstat* jstat

* create expenditure variable
	gen lpce = log(pce)
	replace lpce = 0.00001 if pce == 0
	
* expenditure previous period
	sort pidlink year
	bys pidlink (year) : gen lpce_lag = lpce[_n-1]

* identifying household without household head
	bys year hhid: egen min_ar02b=min(ar02b)	
	g nohhhead=min_ar02b>1

* indicate if there is no spouse of household head
	g spouse_hhhead=ar02b==2
	bys year hhid: egen num_spouse_hhhead=total(spouse_hhhead)
	g spouse_hhhead_exist=num_spouse_hhhead>0

* Wave
	g wave = 4 if year == 2007
	replace wave = 5 if year == 2014	

* save data	
save "$input/ifls-append-individual.dta", replace

* ==== EDUCATION HISTORY DATA ==== *

* DLA section
	use "$input/ifls-append-individual.dta", clear

	* keep only obs in children education history module (dla2)
	keep if dla701<.

	* keep only 2014 data
	keep if year==2014

	loc s1 "sd"
	loc s2 "smp"
	loc s3 "sma"

	forval i = 1/3 {
		forval j=2007/2014 {
			di as res "enter school in `j'" 
			g enter_`s`i''_`j'= dla71a`i'==`j'

			di as res "enter school after `j'"
			g enter_`s`i''_post_`j'= dla71a`i'>`j' & dla71a`i'<.

			di as res "left school in `j'" 
			g leave_`s`i''_`j'= dla71f`i'==`j' 
			
			di as res "left school before `j'"
			g leave_`s`i''_pre_`j'= dla71f`i'<`j'  

			di as res "enrolled if enter school in `j'"
			g enrolled_`s`i''_`j'=1 if enter_`s`i''_`j'==1

			di as res "enrolled if haven't left school by `j'"
			replace enrolled_`s`i''_`j'=1 if leave_`s`i''_pre_`j'==0
			
			* note that Merapi eruption happened late 2010, so anyone leaving school in 2010
			* must have done so before the eruption, since new academic year starts midyear
			* we do not have exact date on when the student leave. so we assume that it is
			* unlikely that a student leave school only a few months after the new academic year starts 
			di as res "not enrolled if leave school in `j'"
			replace enrolled_`s`i''_`j'=0 if leave_`s`i''_`j'==1
			
			di as res "not enrolled if enter school after `j'"
			replace enrolled_`s`i''_`j'=0 if enter_`s`i''_post_`j'==1		

			di as res "not enrolled if entry year is missing (has not reached that level of edu yet)"
			replace enrolled_`s`i''_`j'=0 if dla71a`i'==.				

			di as res "change enrollment status to missing if entry or leaving year is unknown"
			replace enrolled_`s`i''_`j'=. if inlist(dla71a`i',9998,9999)|inlist(dla71f`i',9998,9999)
		}
		
		di as res "indicate if adult education (kejar paket), school for disabled, and others"
		g exclude_`s`i''=inlist(dla70`i',11,12,15,17,95)
		
		* correcting for temporary leave
		loc timea start
		loc timeb end

		forval y = 1/3 {
			foreach x in a b {
				replace dla74c`y'`x'mth`i'=. if dla74c`y'`x'mth`i'==98 
				replace dla74c`y'`x'yr`i'=. if dla74c`y'`x'yr`i'==9998
				g slash="/"
				egen templeave_`time`x''_`s`i''_`y'= concat(dla74c`y'`x'yr`i' slash dla74c`y'`x'mth`i')
				replace templeave_`time`x''_`s`i''_`y'= subinstr(templeave_`time`x''_`s`i''_`y',"./.","",.)
				replace templeave_`time`x''_`s`i''_`y'= subinstr(templeave_`time`x''_`s`i''_`y',".","",.)
				g datelength=strlen(templeave_`time`x''_`s`i''_`y')
				replace templeave_`time`x''_`s`i''_`y'= subinstr(templeave_`time`x''_`s`i''_`y',"/","/0",.) if datelength==6
				replace templeave_`time`x''_`s`i''_`y'= subinstr(templeave_`time`x''_`s`i''_`y',"/","",.)
				destring templeave_`time`x''_`s`i''_`y', replace
				replace templeave_`time`x''_`s`i''_`y'=. if datelength<6
				drop slash datelength
			}
			* this construction will assume that those who left school temporarily in Oct 2010 do so out
			* of their own volition and not because of the Merapi eruption. This is because Merapi erupted
			* in late Oct 2010 and the ashfall was still very light in the beginning.
			g sleave_pre_oct2010_`s`i''_`y'= templeave_start_`s`i''_`y'<=201010 
			g eleave_post_oct2010_`s`i''_`y'= templeave_end_`s`i''_`y'>201010 & templeave_start_`s`i''_`y'<.
			replace enrolled_`s`i''_2010=0 if sleave_pre_oct2010_`s`i''_`y'==1 & eleave_post_oct2010_`s`i''_`y'==1
			
			* this construction will assume that those who left school temporarily in Jan 2014 do so out
			* of their own volition and not because of the Kelud eruption. This is because Kelud erupted
			* in mid Feb 2014
			g sleave_pre_jan2014_`s`i''_`y'= templeave_start_`s`i''_`y'<=201401
			g eleave_post_jan2014_`s`i''_`y'= templeave_end_`s`i''_`y'>201401 & templeave_start_`s`i''_`y'<.
			replace enrolled_`s`i''_2013=0 if sleave_pre_jan2014_`s`i''_`y'==1 & eleave_post_jan2014_`s`i''_`y'==1
		}
	}
	
	* correcting observations that are both enrolled in SD and SMP
	* if the finish date of SD is later than the start date of SMP, then the children is enrolled in SD
	foreach x of numlist 2010 2013 {
		replace enrolled_smp_`x'=0 if enrolled_sd_`x'==1 & enrolled_smp_`x'==1 
	}

	* save data
	keep year hhid id enrolled* exclude*
	save "$input/ifls-append-eduhist-below15yo.dta", replace 

* DL section
	use "$input/ifls-append-individual.dta", clear

	* remove children (<15 yo) from the dataset
	drop if dla701<.

	* keep only 2014 data
	keep if year==2014

	loc s1 "sd"
	loc s2 "smp"
	loc s3 "sma"

	forval i = 1/3 {
		forval j=2007/2014 {
			di as res "enter school in `j'"
			g enter_`s`i''_`j'= dl11a`i'==`j'

			di as res "enter school after `j'"
			g enter_`s`i''_post_`j'= dl11a`i'>`j' & dl11a`i'<.

			di as res "left school in `j'" 
			g leave_`s`i''_`j'= dl11f`i'==`j' 

			di as res "left school before `j'"
			g leave_`s`i''_pre_`j'= dl11f`i'<`j'  

			di as res "enrolled if enter school in `j'"
			g enrolled_`s`i''_`j'=1 if enter_`s`i''_`j'==1

			di as res "enrolled if haven't left school by `j'"
			replace enrolled_`s`i''_`j'=1 if leave_`s`i''_pre_`j'==0

			* note that Merapi eruption happened late 2010, so anyone leaving school in 2010
			* must have done so before the eruption, since new academic year starts midyear
			* we do not have exact date on when the student leave. so we assume that it is
			* unlikely that a student leave school only a few months after the new academic year starts 
			di as res "not enrolled if leave school in `j'" 
			replace enrolled_`s`i''_`j'=0 if leave_`s`i''_`j'==1

			di as res "not enrolled if enter school after `j'"
			replace enrolled_`s`i''_`j'=0 if enter_`s`i''_post_`j'==1		

			di as res "not enrolled if entry year is missing (has not reached that level of edu yet)"
			replace enrolled_`s`i''_`j'=0 if dl11a`i'==.				

			di as res "change enrollment status to missing if entry or leaving year is unknown"
			replace enrolled_`s`i''_`j'=. if inlist(dl11a`i',9998,9999)|inlist(dl11f`i',9998,9999)
		}
		
		di as res "indicate if adult education (kejar paket), school for disabled, and others"
		g exclude_`s`i''=inlist(dl10`i',11,12,15,17,95)
	
		* correcting for temporary leave
		loc timea start
		loc timeb end

		forval y = 1/3 {
			foreach x in a b {
				replace dl14c`y'`x'mth`i'=. if dl14c`y'`x'mth`i'==98 
				replace dl14c`y'`x'yr`i'=. if dl14c`y'`x'yr`i'==9998
				g slash="/"
				egen templeave_`time`x''_`s`i''_`y'= concat(dl14c`y'`x'yr`i' slash dl14c`y'`x'mth`i')
				replace templeave_`time`x''_`s`i''_`y'= subinstr(templeave_`time`x''_`s`i''_`y',"./.","",.)
				replace templeave_`time`x''_`s`i''_`y'= subinstr(templeave_`time`x''_`s`i''_`y',".","",.)
				g datelength=strlen(templeave_`time`x''_`s`i''_`y')
				replace templeave_`time`x''_`s`i''_`y'= subinstr(templeave_`time`x''_`s`i''_`y',"/","/0",.) if datelength==6
				replace templeave_`time`x''_`s`i''_`y'= subinstr(templeave_`time`x''_`s`i''_`y',"/","",.)
				destring templeave_`time`x''_`s`i''_`y', replace
				replace templeave_`time`x''_`s`i''_`y'=. if datelength<6
				drop slash datelength
			}
			* this construction will assume that those who left school temporarily in Oct 2010 do so out
			* of their own volition and not because of the Merapi eruption. This is because Merapi erupted
			* in late Oct 2010 and the ashfall was still very light in the beginning.
			g sleave_pre_oct2010_`s`i''_`y'= templeave_start_`s`i''_`y'<=201010 
			g eleave_post_oct2010_`s`i''_`y'= templeave_end_`s`i''_`y'>201010 & templeave_start_`s`i''_`y'<.
			replace enrolled_`s`i''_2010=0 if sleave_pre_oct2010_`s`i''_`y'==1 & eleave_post_oct2010_`s`i''_`y'==1
			
			* this construction will assume that those who left school temporarily in Jan 2014 do so out
			* of their own volition and not because of the Kelud eruption. This is because Kelud erupted
			* in mid Feb 2014
			g sleave_pre_jan2014_`s`i''_`y'= templeave_start_`s`i''_`y'<=201401
			g eleave_post_jan2014_`s`i''_`y'= templeave_end_`s`i''_`y'>201401 & templeave_start_`s`i''_`y'<.
			replace enrolled_`s`i''_2013=0 if sleave_pre_jan2014_`s`i''_`y'==1 & eleave_post_jan2014_`s`i''_`y'==1
		}
	}

	* correcting enrollment of special case observations
	foreach x of numlist 2010 2013 {
		foreach y in sd smp sma {
			replace enrolled_`y'_`x'=0 if hhid=="1732851" & id==2
		}
		replace enrolled_smp_`x'=0 if hhid=="0051300" & id==12
	}
	replace enrolled_sd_2013=0 if hhid=="1803000" & id==8 // 2013 this person is enrolled in SMP
	replace enrolled_sd_2013=0 if hhid=="2371200" & id==6 // 2013 this person is enrolled in SMA
	replace enrolled_smp_2013=0 if enrolled_smp_2013==1 & enrolled_sma_2013==1	

	* save data
	keep year hhid id enrolled* exclude*
	save "$input/ifls-append-eduhist-above15yo.dta", replace 
	
* ==== MIGRATION HISTORY DATA ==== *

	loc mgyr1 2013	2012	2011	2010	2009	2008	2007	2006	2005	2004	2003	2002	2001	2000	///
	1999	1998	1997	1996	1995	1994	1993	1992	1991	1990	1989	1988	1987	1986	1985	///
	1984	1983	1982	1981	1980	1979	1978	1977	1976	1975	1974	1973	1972	1971	1970	///
	1969	1968	1967	1966	1965	1964	1963	1962	1961	1960	1959	1958	1957	1956	1954	///
	1951	1950	1947

	* filling in location names for those who migrated
	foreach i of numlist `mgyr1' {
		use "$input/ifls-migration.dta", clear
		
		ren mg21d`i' provid`i'
		ren mg21c`i' kabid`i'
		ren mg21b`i' kecid`i'
		foreach y in prov kab kec {
			g `y'nm`i'=""	
		}
		
		keep if migrate`i'==1
		keep hhid id prov*`i' kab*`i' kec*`i'
		
		foreach x in provid kabid kecid {
			clonevar `x'14=`x'`i'
		}

		merge m:1 provid14 kabid14 kecid14 using "$ifls/IFLS5_BPS_2014_codes/bps2014.dta", gen(m_bps2014)
		drop if m_bps2014==2
		drop m_bps2014		
		
		foreach x in provnm kabnm kecnm {
			replace `x'`i'=`x'14
		}
		
		drop prov*14 kab*14 kec*14
		
		tempfile temp`i'
		save `temp`i'', replace
	}
		
	* location names for the remaining
	use "$input/ifls-migration.dta", clear

	* panel obs
	foreach x in 07 14 {
		foreach y in id nm {
			foreach z in prov kab kec {
				clonevar `z'`y'20`x'=`z'`y'`x'
			}
		}
	}
	
	foreach x of varlist prov*2007 kab*2007 kec*2007 {
		bys pidlink (year) : replace `x' = `x'[_n-1] if year == 2014 	
	}
	
	keep if year==2014
	
	* nonpanel obs
	foreach i of numlist `mgyr1' {
		if `i'~=2007 {
			ren mg21d`i' provid`i'
			ren mg21c`i' kabid`i'
			ren mg21b`i' kecid`i'	
		}
		merge 1:1 hhid id using `temp`i'', nogen update	
	}
	
	loc mgyr2 2006	2005	2004	2003	2002	2001	2000	///
	1999	1998	1997	1996	1995	1994	1993	1992	1991	///
	1990	1989	1988	1987	1986	1985	1984	1983	1982	///
	1981	1980	1979	1978	1977	1976	1975	1974	1973	///
	1972	1971	1970	1969	1968	1967	1966	1965	1964	///
	1963	1962	1961	1960	1959	1958	1957	1956	1954	///
	1951	1950	1947
	
	foreach i of numlist `mgyr2' {
		foreach y in prov kab kec {
			forval j=2006/2007 {
				replace `y'id`j'=`y'id`i' if `y'id`j'==.				
				replace `y'nm`j'=`y'nm`i' if `y'nm`j'==""				
			}
		}	
	}
	
	foreach x in prov kab kec {
		foreach y in id nm {
			forval i=2008/2013 {
				loc j=`i'-1
				replace `x'`y'`i'=`x'`y'`j' if migrate`i'==0
			}

		}
	}
	
	* location names for original residence
	foreach x in id nm {
		drop prov`x'14 kab`x'14 kec`x'14	
	}
	clonevar provid14=provori 
	clonevar kabid14=kabori
	clonevar kecid14=kecori
	
	merge m:1 provid14 kabid14 kecid14 using "$ifls/IFLS5_BPS_2014_codes/bps2014.dta", gen(m_bps2014)
	drop if m_bps2014==2
	drop m_bps2014		
	
	ren (provnm14 kabnm14 kecnm14 provid14 kabid14 kecid14) ///
		(mg05provnm mg05kabnm mg05kecnm mg05provid mg05kabid mg05kecid)
	
	forval i=2006/2013 {
		foreach x in prov kab kec {
			replace `x'id`i'=mg05`x'id if `x'id`i'==.	
			replace `x'nm`i'=mg05`x'nm if `x'nm`i'==""
		}
	}
	
	drop mg21* mg05* 
	keep hhid id year *2006 *2007 *2008 *2009 *2010 *2011 *2012 *2013 *2014 *ori mg00x
	
	save "$input/ifls-migration-history.dta", replace
	
* ==== HOUSEHOLD HEAD & SPOUSE DATA ==== *
	loc h1 "hhhead"
	loc h2 "hhhead_spouse"

	* age, sex, education, religion, ethnicity, and employment of household head and spouse
	forval i=1/2 {
		use "$input/ifls-append-individual.dta", clear
		merge 1:1 hhid id year using "$input/ifls-migration-history.dta", nogen
	
		keep if ar02b==`i'
		keep year hhid age sex edu_attend length_schooling ethnic1-ethnic7 relig_islam jobstat workstat* age20* ///
		migrate* mg* prov*20* kab*20* kec*20*

		ren (age sex edu_attend length_schooling relig_islam jobstat) ///
			(age_`h`i'' sex_`h`i'' edu_`h`i'' length_schooling_`h`i'' islam_`h`i'' jobstat_`h`i'')
		foreach x of varlist ethnic* workstat* age20* migrate* mg* prov*20* kab*20* kec*20* {
			ren `x' `x'_`h`i''
		} 

		g agesq_`h`i''= age_`h`i''^2

		* for more than one household head/spouse, pick the eldest one
		bys year hhid: egen age_oldest_`h`i''=max(age_`h`i'')
		keep if age_`h`i''== age_oldest_`h`i''

		* if there are more than one oldest household head/spouse, pick the one with the higher education 
		bys year hhid: egen ls_oldest_`h`i''= max(length_schooling_`h`i'')
		keep if length_schooling_`h`i''== ls_oldest_`h`i''

		* if there are still duplicates, random drop
		duplicates drop year hhid, force 
		
		* save data
		drop ls_oldest_`h`i'' age_oldest_`h`i''
		save "$input/ifls-`h`i''.dta", replace
	}

* ==== OLDEST MAN & WOMAN DATA ==== *
	* education, religion, ethnicity, employment, age of oldest man in the household
	loc s0 "woman"
	loc s1 "man"

	forval i = 0/1 {
		use "$input/ifls-append-individual.dta", clear
		merge 1:1 hhid id year using "$input/ifls-migration-history.dta", nogen

		bys year hhid: egen oldest_age_`s`i''=max(age) if sex==`i'
		g oldest_`s`i''= age==oldest_age_`s`i''

		keep if oldest_`s`i''==1
		keep year hhid age edu_attend length_schooling ethnic1-ethnic7 relig_islam jobstat workstat* age20* ///
		migrate* mg* prov*20* kab*20* kec*20*

		ren (age edu_attend length_schooling relig_islam jobstat) ///
		(age_oldest`s`i'' edu_oldest`s`i'' length_schooling_oldest`s`i'' islam_oldest`s`i'' jobstat_oldest`s`i'')
		foreach x of varlist ethnic* workstat* age20* migrate* mg* prov*20* kab*20* kec*20* {
			ren `x' `x'_oldest`s`i''
		}

		g agesq_oldest`s`i''= age_oldest`s`i''^2 

		* if there are duplicates, pick the one with the higher education 
		bys year hhid: egen longest_schooling_oldest`s`i''= max(length_schooling_oldest`s`i'')
		keep if length_schooling_oldest`s`i''== longest_schooling_oldest`s`i''	

		* if there are still duplicates, pick the one working
		duplicates tag year hhid, gen(dup1)
		g oldest`s`i''_working=	jobstat_oldest`s`i''<5
		drop if oldest`s`i''_working==0 & dup1>0

		* if there are still duplicates, pick the one who is not a casual worker
		duplicates tag year hhid, gen(dup2)
		g oldest`s`i''_notcasualworker= jobstat_oldest`s`i''<4
		drop if oldest`s`i''_notcasualworker==0 & dup2>0	

		* if there are still duplicates, random drop
		duplicates drop year hhid, force 

		* save data
		keep year hhid *oldest`s`i''
		drop longest_schooling_oldest`s`i''
		save "$input\ifls-oldest`s`i''.dta", replace
	} 

* ==== PARENT DATA ==== *
	* father's and mother's education, employment, religion, ethnicity, age
	foreach y in father mother {
		use "$input/ifls-append-individual.dta", clear
		merge 1:1 hhid id year using "$input/ifls-migration-history.dta", nogen
		tempfile all
		save `all', replace 
		
		keep year hhid `y'_id
		duplicates drop year hhid `y'_id, force
		ren `y'_id `y'_idx
		clonevar id=`y'_idx
	
		merge 1:1 year hhid id using `all'
		drop if _merge==1 // the person is no longer on roster
		keep if id==`y'_idx // means the person is a father/mother

		keep year hhid id edu_attend length_schooling relig_islam ethnic1-ethnic7 jobstat age workstat* age20* ///
		migrate* mg* prov*20* kab*20* kec*20*
		
		ren (edu_attend length_schooling relig_islam jobstat age) ///
		(edu_`y' length_schooling_`y' islam_`y' jobstat_`y' age_`y')
		foreach x of varlist ethnic* workstat* age20* migrate* mg* prov*20* kab*20* kec*20* {
			ren `x' `x'_`y'
		} 

		g agesq_`y'=age_`y'^2
		ren id `y'_id

		keep year hhid `y'_id *`y' 
		save "$input/ifls-`y'.dta", replace 
	}

* ==== MERGING ==== *			

* Combine DL and DLA
	use "$input/ifls-append-eduhist-above15yo.dta", clear 
	append using "$input/ifls-append-eduhist-below15yo.dta"	
	
	* create general enrollment variable and a single variable to indicate education level
	forval x=2007/2014 {
		g enrolled_`x'=enrolled_sd_`x'==1|enrolled_smp_`x'==1|enrolled_sma_`x'==1
		g edu_`x'=1 if enrolled_sd_`x'==1
		replace edu_`x'=2 if enrolled_smp_`x'==1
		replace edu_`x'=3 if enrolled_sma_`x'==1
	}

* Combine with individual data
	merge 1:1 year hhid id using "$input/ifls-append-individual.dta", nogen
	foreach x of varlist enrolled* {
		bys pidlink (year) : replace `x' = `x'[_n+1] if year == 2007 		
	}

* Merge with household head & spouse & oldestman & oldestwoman data
	foreach x in hhhead hhhead_spouse oldestman oldestwoman {
		merge m:1 year hhid using "$input/ifls-`x'", nogen 
	}

* Merge with father & mother data
	foreach x in father mother {
		merge m:1 year hhid `x'_id using "$input/ifls-`x'", nogen 
	}

* Filling in missing value of parents data
	foreach x in edu length_schooling ethnic1 ethnic2 ethnic3 ethnic4 ethnic5 ethnic6 ethnic7 islam jobstat age agesq {
		replace `x'_father=`x'_hhhead if `x'_father==. & sex_hhhead==1
		replace `x'_father=`x'_hhhead_spouse if `x'_father==. & sex_hhhead==0
		replace `x'_father=`x'_oldestman if `x'_father==. & sex_hhhead==0 & spouse_hhhead_exist==0 
		replace `x'_mother=`x'_hhhead if `x'_mother==. & sex_hhhead==0
		replace `x'_mother=`x'_hhhead_spouse if `x'_mother==. & sex_hhhead==1
		replace `x'_mother=`x'_oldestwoman if `x'_mother==. & sex_hhhead==1 & spouse_hhhead_exist==0
	}
	
	forval i = 2007/2014 {
		foreach x in workstat age  {
			replace `x'`i'_father=`x'`i'_hhhead if `x'`i'_father==. & sex_hhhead==1
			replace `x'`i'_father=`x'`i'_hhhead_spouse if `x'`i'_father==. & sex_hhhead==0
			replace `x'`i'_father=`x'`i'_oldestman if `x'`i'_father==. & sex_hhhead==0 & spouse_hhhead_exist==0 
			replace `x'`i'_mother=`x'`i'_hhhead if `x'`i'_mother==. & sex_hhhead==0
			replace `x'`i'_mother=`x'`i'_hhhead_spouse if `x'`i'_mother==. & sex_hhhead==1
			replace `x'`i'_mother=`x'`i'_oldestwoman if `x'`i'_mother==. & sex_hhhead==1 & spouse_hhhead_exist==0
		}
	}

	forval i = 2006/2014 {
		foreach x in provid kabid kecid {
			replace `x'`i'_father=`x'`i'_hhhead if `x'`i'_father==. & sex_hhhead==1
			replace `x'`i'_father=`x'`i'_hhhead_spouse if `x'`i'_father==. & sex_hhhead==0
			replace `x'`i'_father=`x'`i'_oldestman if `x'`i'_father==. & sex_hhhead==0 & spouse_hhhead_exist==0 
			replace `x'`i'_mother=`x'`i'_hhhead if `x'`i'_mother==. & sex_hhhead==0
			replace `x'`i'_mother=`x'`i'_hhhead_spouse if `x'`i'_mother==. & sex_hhhead==1
			replace `x'`i'_mother=`x'`i'_oldestwoman if `x'`i'_mother==. & sex_hhhead==1 & spouse_hhhead_exist==0
		}
	}

	forval i = 2006/2014 {
		foreach x in provnm kabnm kecnm {
			replace `x'`i'_father=`x'`i'_hhhead if `x'`i'_father=="" & sex_hhhead==1
			replace `x'`i'_father=`x'`i'_hhhead_spouse if `x'`i'_father=="" & sex_hhhead==0
			replace `x'`i'_father=`x'`i'_oldestman if `x'`i'_father=="" & sex_hhhead==0 & spouse_hhhead_exist==0 
			replace `x'`i'_mother=`x'`i'_hhhead if `x'`i'_mother=="" & sex_hhhead==0
			replace `x'`i'_mother=`x'`i'_hhhead_spouse if `x'`i'_mother=="" & sex_hhhead==1
			replace `x'`i'_mother=`x'`i'_oldestwoman if `x'`i'_mother=="" & sex_hhhead==1 & spouse_hhhead_exist==0
		}
	}	
	
	forval i = 2006/2013 {
		foreach x in mg36 {
			replace `x'`i'_father=`x'`i'_hhhead if `x'`i'_father=="" & sex_hhhead==1
			replace `x'`i'_father=`x'`i'_hhhead_spouse if `x'`i'_father=="" & sex_hhhead==0
			replace `x'`i'_father=`x'`i'_oldestman if `x'`i'_father=="" & sex_hhhead==0 & spouse_hhhead_exist==0 
			replace `x'`i'_mother=`x'`i'_hhhead if `x'`i'_mother=="" & sex_hhhead==0
			replace `x'`i'_mother=`x'`i'_hhhead_spouse if `x'`i'_mother=="" & sex_hhhead==1
			replace `x'`i'_mother=`x'`i'_oldestwoman if `x'`i'_mother=="" & sex_hhhead==1 & spouse_hhhead_exist==0
		}
	}	
	
	foreach y in father mother hhhead {
		qui levelsof jobstat_`y'
		foreach x of numlist `r(levels)' {
			g jobstat_`y'_`x'=jobstat_`y'==`x'
		}
	}
	
* merge migration data
	merge 1:1 hhid id year using "$input\ifls-migration-history.dta", nogen
	
* correcting child migration
forval i = 2006/2013 {
	foreach y in hhhead mother father {
		foreach x in prov kab kec {
			replace `x'id`i'=`x'id`i'_`y' if `x'id`i'==. & regexm(mg36`i'_`y',"G")			
			replace `x'nm`i'=`x'nm`i'_`y' if `x'nm`i'=="" & regexm(mg36`i'_`y',"G")
		}
		replace migrate`i'=migrate`i'_`y' if migrate`i'==. & regexm(mg36`i'_`y',"G")
	}
	replace migrate`i'=0 if migrate`i'==.		
}
	
	foreach x in prov kab kec {
		forval i=2007/2013 {
			loc j=`i'-1
			replace `x'id`i'=`x'id`j' if migrate`i'==0 & `x'id`i'==.
			replace `x'nm`i'=`x'nm`j' if migrate`i'==0 & `x'nm`i'==""
		}
	}
	
* Save data
	save "$input/ifls-panel-all.dta", replace 
