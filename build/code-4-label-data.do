* ******************************************************************************
* PROGRAM: PAPER 1
* PROGRAMMER: Lolita Moorena
* PURPOSE: LABEL ALL IMPORTANT VARIABLES
* DATE CREATED: 13 April 2023
* LATEST MODIFICATION: -
* ******************************************************************************

use "$input/ifls-panel-all.dta", clear

* install labvars
// ssc install labvars, replace

* AR section
	la var membernumber "ar00 HH member number"
	la var rel_head "ar02 Relation with HH head"
	la var female "ar07 Female"
	la var birth_year "ar08yr Year of birth"
	la var age "age (constructed from ptrack)"
	la var marital "ar13 Marital status"
		la def MARITAL 1 "unmarried" 2 "married" 3 "separated" 4 "divorced" 5 "widow"
		la val marital MARITAL
		
	la var relig_islam "ar15 Islam"
	la var relig_excislam "ar15 Non-Islam"
	la var father_id "ar10 Father ID number"
	la var mother_id "ar11 Mother ID number"
	la var carer_id "ar12 Carer ID number"
	la var spouse_id "ar14 Spouse ID number"
	
	la var edu_attend "ar16 Education level attended"
		la def EDU 0 "no formal edu" 1 "primary edu" 2 "secondary edu" 3 "high school" 4 "tertiary edu"
		la val edu_attend EDU
	la var edu_completed "ar17 Education level completed"
		la val edu_completed EDU
	la var in_school "In school"

* SC section
	la var idprov "sc01 Province"
	la var idkab "sc02 District"
	la var idkec "sc03 Subdistrict"
	la var urban "sc05 Living in urban area"	
	
* UT section
	la var have_farm "ut00a Have land farming"
	la var area_farm "ut00b Area (m2)"
	
* KR section
	la var electricity "kr11 Own a house"
	la var social_assistance "kr27 Use any assistance"
	la var tv "kr24a Have TV"
	la var family_card "kr27k Have family card"
	
* HR section
	local alph A B C D1 D2 D3 E F G H J K1 K2
	foreach var of local alph{
		la var hr01`var' "hr01 Asset `var'"
	}

* ND section
	la var disaster_assist "nd16 Receive assistance"
	la var disaster_assist_amt "nd17 Receive assistance"
	la var disaster_temphouse "nd18 Temporary housing"
	
// loc dA "Flood"
// loc dB "Land/mudslide"
// loc dC "Mudflow"
// loc dD "Volcanic eruption"
// loc dE "Earthquake"
// loc dF "Tsunami"
// loc dG "Windstorm"
// loc dH "Forest fire"
// loc dI "Fire"
// loc dJ "Civil strife"
// loc dS "Drought"

// foreach x in A B D E F G H I J S {
// 	labvars nd04`x' "`d`x'' freq in the last 5 years" ///                   
// 			nd05m`x' "`d`x'' most severe in the last 5 years: month" ///
// 			nd05y`x' "`d`x'' most severe in the last 5 years: year" ///
// 			nd14`x' "`d`x'' house damage" ///
// 			nd15`x' "Repair/rebuilt house after `d`x''?" ///
// 			nd16`x'	"Receive assistance from gov or ngo during `d`x''?" ///
// 			nd17`x' "Amount of assistance for `d`x''" ///
// 			nd18`x' "Any HH member lived without housing or temporary housing for some time after `d`x''?" ///
// 			nd19`x'	"Housing status in nd18 after `d`x''" ///
// 			nd20`x' "How long did the HH member lived in temporary housing after `d`x''?" ///
// 			nd20xx`x' "How long did the HH member lived in temporary housing after `d`x''?" ///
// 			nd21`x'	"Have you returned after `d`x''?" ///
// 			nd01`x' "Affected by `d`x''" ///
// 			, alternate
// }

/*
* BH section
	la var loan_know "Know of loan sources"
	la var loan_secure "Able to secure a loan"
*/

* TK section
	forval i = 1/5 {
		loc js: lab jstat `i'
		loc jsx=substr("`js'",3,.)
		foreach x in father mother {
			la var jobstat_`x'_`i' "`jsx'"
		} 
	} 

* OTHERS
	la var pce "Expenditure per capita"
	la var lpce "Log expenditure per cap"
	la var lpce_lag "Log expend. percap. (lag)"

	foreach x of numlist 2010 2013 {
		labvars enrolled_sd_`x' "Enrolled in SD in `x'" ///
				enrolled_smp_`x' "Enrolled in SMP in `x'" ///
				enrolled_sma_`x' "Enrolled in SMA in `x'" ///
				edu_`x' "Level of education in `x'" ///
				age_byac_`x' "Age by academic year `x'" ///
				, alternate
	}
			
	labvars	isworkinga "Working in the past 12 months" ///
			isworkingb "Ever worked" ///
			isworkingc "Worked during school" ///
			isworkingd "Combination of a-c" ///
			failgrade "Ever failed a grade" ///
			tempabsent "Ever temporary absent from school for extended period" ///
			masonry "Wall material of the house is masonry" ///
			, alternate

	la def edu 1 "1 SD" 2 "2 SMP" 3 "3 SMA"
	la val edu_2010 edu_2013 edu

// * order variable
// order nd*, last
// foreach x in A B D E F G H I J S {
// 	order nd17`x', after(nd16`x')
// }

save "$input/ifls-panel-all-label.dta", replace

