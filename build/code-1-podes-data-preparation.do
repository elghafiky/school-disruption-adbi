* ******************************************************************************
* PROGRAM: MT MERAPI
* PROGRAMMER: Lolita Moorena
* PURPOSE: DATA PREPARATION
* DATE CREATED: 2 July 2023
* LATEST MODIFICATION: -
* ******************************************************************************

* merge the names of the areas for podes 2008

	import excel "/$raw/2 PODES/kode prov kab kec.xls", sheet("prov") cellrange(B3:C35) allstring clear
	rename B province
	rename C province_name
	save "$temp/podes08-prov.dta", replace
	
	import excel "/$raw/2 PODES/kode prov kab kec.xls", sheet("kab") cellrange(B3:C499) allstring clear
	gen province = substr(B,1,2)
	gen district = substr(B,3,2)
	rename C district_name
	save "$temp/podes08-kab.dta", replace

	import excel "/$raw/2 PODES/kode prov kab kec.xls", sheet("kec") cellrange(B3:C6655) allstring clear
	gen province = substr(B,1,2)
	gen district = substr(B,3,2)
	gen hamlet = substr(B,5,3)
	rename C hamlet_name
	save "$temp/podes08-kec.dta", replace
	
	use "$temp/podes08-prov.dta", clear 
	merge 1:m province using "$temp/podes08-kab.dta"
	drop _m
	merge 1:m province district using "$temp/podes08-kec.dta"
	drop _m B
	
	save "$raw/2 PODES/PODES 2008/podes08-areaname.dta", replace
	
* only year 2008 and 2014
local year 08 14

foreach yy of local year {

	if `yy' > 90 local y = 1900 + `yy'
	else if `yy' < 30 local y = 2000 + `yy'
		di "`y'"
	
		if `y' == 1993 {
			gen province = b1r1
			gen district = b1r2
			gen hamlet = b1r4
			gen village = b1r5
			gen area_village = b9a
			
			* gen urban b3r1 or b1r6
			
			gen hh_farm = b13aa01 // jumlah rumah tangga pertanian
			egen market = rowtotal(b13b01 b13b02 b13b03 b13b04c) // pasar bangunan permanen, nonpermanen, dan hewanm dab ujab
			gen bank = b13c1a // bank umum/tabungan/pembangunan
			egen bpr = rowtotal(b13c1b1 b13c1b2 b13c1b3 b13c1b4 b13c1b5)
			gen hh_PLNelectricity = b13d1a
			
			gen disaster_dry = b3r14a // kekeringan
			gen disaster_flood = b3r14b // banjir
			gen disaster_earthquake = b3r14c // earthquake
			gen disaster_volcano = b3r14d // volcano
			gen disaster_others = b3r14e // others
			
			gen number_hh = b4ar3b
			
			gen hh_house_permanent = b4br11a
			egen hh_house_temporary = rowtotal(b4br11b b4br11c)
			
			* 0 kindergarten
			egen school_0 = rowtotal(b5r1ak4 b5r1ak5) // banyaknya sekolah
			egen teacher_0 = rowtotal(b5r1ak6 b5r1ak7)
			egen student_0 = rowtotal(b5r1ak8 b5r1ak9)
			* 1 primary
			egen school_1 = rowtotal(b5r1b1k4 b5r1b1k5 b5r1b2k4 b5r1b2k5) // banyaknya sekolah
			egen teacher_1 = rowtotal(b5r1b1k6 b5r1b1k7 b5r1b2k6 b5r1b2k7)
			egen student_1 = rowtotal(b5r1b1k8 b5r1b1k9 b5r1b2k8 b5r1b2k9)
			* 2 lower secondary
			egen school_2 = rowtotal(b5r1c1k4 b5r1c1k5 b5r1c2k4 b5r1c2k5) // banyaknya sekolah
			egen teacher_2 = rowtotal(b5r1c1k6 b5r1c1k7 b5r1c2k6 b5r1c2k7)
			egen student_2 = rowtotal(b5r1c1k8 b5r1c1k9 b5r1c2k8 b5r1c2k9)
			* 3 upper secondary
			egen school_3 = rowtotal(b5r1d1k4 b5r1d1k5 b5r1d2k4 b5r1d2k5) // banyaknya sekolah
			egen teacher_3 = rowtotal(b5r1d1k6 b5r1d1k7 b5r1d2k6 b5r1d2k7)
			egen student_3 = rowtotal(b5r1d1k8 b5r1d1k9 b5r1d2k8 b5r1d2k9)
			
			gen water = b7r4a // drink water
			
		} 
		
		if `y' == 1996 {
			gen province = b3r9b1b
			gen district = b3r9b1c
			gen hamlet = b3r9b1d
			gen village = b3r9b1e
			gen area_village = b10a
			
			* gen urban b3r1 or b1r6
			
			gen hh_farm = b11er2 // jumlah rumah tangga pertanian
			egen market = rowtotal(b11ar2a b11ar3 b11ar4 b11ar5) // pasar bangunan permanen, nonpermanen, dan hewanm dab ujab
			egen bank = rowtotal(b11cr1a b11cr1b b11cr2b1) // bank umum/tabungan/pembangunan
			egen bpr = rowtotal(b11cr2a1 b11cr2a2 b11cr2b1 b11cr2b2)
			gen hh_PLNelectricity = b11er3a
			
			gen number_hh = b4ar2c
			
			* 0 kindergarten
			egen school_0 = rowtotal(b5r1ak2 b5r1ak3 b5r1ak4 b5r1ak5) // banyaknya sekolah
			* 1 primary
			egen school_1 = rowtotal(b5r1bk2 b5r1bk3 b5r1bk4 b5r1bk5) // banyaknya sekolah
			* 2 lower secondary
			egen school_2 = rowtotal(b5r1ck2 b5r1ck3 b5r1ck4 b5r1ck5) // banyaknya sekolah
			* 3 upper secondary
			egen school_3 = rowtotal(b5r1dk2 b5r1dk3 b5r1dk4 b5r1dk5) // banyaknya sekolah
			
			gen water = b8r4a // drink water
			
		} 

		if `y' == 1999 {
			gen province = prop
			gen district = kab
			gen hamlet = kec
			gen village = desa
			gen area_village = b10a
			
			* gen urban b3r1 or b1r6
			
			gen hh_farm = b4ar2c // jumlah rumah tangga pertanian
			egen market = rowtotal(b11ar2a b11ar3 b11ar4 b11ar6) // pasar bangunan permanen, nonpermanen, dan hewanm dab ujab
			gen bank = b11br1 // bank umum/tabungan/pembangunan
			egen bpr = b11br2
			gen hh_PLNelectricity = b4br1a
			
			gen disaster_dry = b4br15b3 // kekeringan
			gen disaster_flood = b4br15b5 // banjir
			gen disaster_earthquake = b4br15b1 // earthquake
			gen disaster_volcano = b4br15b2 // volcano
			gen disaster_others = b4br1510 // others
			
			gen number_hh = b4ar2b
			
			gen hh_house_permanent = b4br8a
			gen hh_house_temporary = b4br8b
			
			* 0 kindergarten
			egen school_0 = rowtotal(b5r1a2 b5r1a3) // banyaknya sekolah
			* 1 primary
			egen school_1 = rowtotal(b5r1b2 b5r1b3) // banyaknya sekolah
			* 2 lower secondary
			egen school_2 = rowtotal(b5r1c2 b5r1c3) // banyaknya sekolah
			* 3 upper secondary
			egen school_3 = rowtotal(b5r1d2 b5r1d3) // banyaknya sekolah
			
			gen water = b8r8a // drink water
			
		} 
				
		if `y' == 2003 {
			gen province = prop
			gen district = kab
			gen hamlet = kec
			gen village = desa
			gen area_village = b10a
			
			* kuesioner podes nga ada
			
		} 
		
		if `y' == 2008 {
					
			use "$raw/2 PODES/PODES `y'/podes`yy'.dta", clear
			gen year = `y'
			
			gen province = prop
			gen district = kab
			gen hamlet = kec
			gen village = desa
			
			* merge the names of the areas for podes 2008
			merge m:1 province district hamlet using "$raw/2 PODES/PODES 2008/podes08-areaname.dta", gen(merge_podes08)

			gen area_village = r1001
			egen area_farm = rowtotal(r1002a r1002b) // sawah dan non-sawah
			
			* gen urban b3r1 or b1r6
			
			// different definition from previous years
			gen hh_farm = r401d // persentase rumah tangga pertanian
			gen market_exist = r1104a == "1" 
				replace market_exist = . if r1104a == ""
			gen market_distance = r1104b
			
			gen hh_PLNelectricity = r501b1
			
			gen disaster_flood = r513b_2 == "1" // banjir
				gen disaster_flood_freq = r513b_3
			gen disaster_earthquake = r513d_2 == "1" // gempabumi
				gen disaster_earthquake_freq = r513d_3
			gen disaster_volcano = r513h_2 == "1" // gempabumi
				gen disaster_volcano_freq = r513h_3
				
			gen number_hh = r401c
			
			* 0 kindergarten
			egen school_0 = rowtotal(r601a_2 r601a_3) // banyaknya sekolah
			gen school_distance_0 = r601a_4
			
			* 1 primary
			egen school_1 = rowtotal(r601b_2 r601b_3) // banyaknya sekolah
			gen school_distance_1 = r601b_4
			
			* 2 lower secondary
			egen school_2 = rowtotal(r601c_2 r601c_3) // banyaknya sekolah
			gen school_distance_2 = r601c_4
			
			* 3 upper secondary
			egen school_3 = rowtotal(r601d_2 r601d_3 r601e_2 r601e_3) // banyaknya sekolah
			egen school_distance_3 = rowmin(r601d_4 r601e_4)
			
			gen hospital = r604a_2 == "1"
			gen hospital_distance = r604a_4
			gen health_center = inlist("1",r604a_2,r604b_2, r604c_2, r604d_2)
			replace health_center = 1 if inlist("1", r604e_2, r604f_2, r604g_2, r604h_2, r604i_2, r604j_2)
			egen health_staff = rowtotal(r606a1 r606a2 r606b r606d)
			
			gen poor_hh = r609
			tab r901a, gen(transport_)
			tab r901b1, gen(road_type_)
			
			gen central_distance = r9022_2
			gen central_duration = r9022_3
			tab r910, gen(phone_signal_)
			
			keep year province district hamlet province_name district_name hamlet_name merge_* village market_* hh* disaster* school* hospital hospital* health* poor* transport_? road_type_? central* phone*
			
		} 
		
		if `y' == 2014 {
			
			use "$raw/2 PODES/PODES `y'/podes_desa_`y'_d1_new.dta", clear
			merge 1:1 r101 r102 r103 r104 using "$raw/2 PODES/PODES `y'/podes_desa_`y'_d2_new.dta"
			drop _m
			merge 1:1 r101 r102 r103 r104 using "$raw/2 PODES/PODES `y'/podes_desa_`y'_d3_new.dta"
			drop _m
			
			gen year = `y'
			
			gen province = r101
			gen district = r102
			gen hamlet = r103
			gen village = r104
			
			gen province_name = r101n
			gen district_name = r102n
			gen hamlet_name = r103n
			gen village_name = r104n
			
			* gen area_village = r1001
			* egen area_farm = rowtotal(r1002a r1002b) // sawah dan non-sawah
			
			* gen urban b3r1 or b1r6
			
			// different definition from previous years
			* gen hh_farm = r401d // persentase rumah tangga pertanian
			
			egen market = rowtotal(r1204a r1204b)
			gen market_exist = market > 0
				replace market_exist = . if market_exist == .
			gen market_distance = r1204c
			
			gen hh_PLNelectricity = r501a1
			
			gen disaster_flood = r601b_k2 == "1" // banjir
				egen disaster_flood_freq = rowmean(r601b_k3 r601b_k5 r601b_k7)
			gen disaster_earthquake = r601d_k2 == "1" // gempabumi
				egen disaster_earthquake_freq = rowmean(r601d_k3 r601d_k5 r601d_k7)
			gen disaster_volcano = r601h_k2 == "1" // gunung meletus
				egen disaster_volcano_freq = rowmean(r601h_k3 r601h_k5 r601h_k7)
			
			* 0 kindergarten
			egen school_0 = rowtotal(r701a_k2 r701a_k3) // banyaknya sekolah
			gen school_distance_0 = r701a_k4
			
			* 1 primary
			egen school_1 = rowtotal(r701b_k2 r701b_k3) // banyaknya sekolah
			gen school_distance_1 = r701b_k4
			
			* 2 lower secondary
			egen school_2 = rowtotal(r701c_k2 r701c_k3) // banyaknya sekolah
			gen school_distance_2 = r701c_k4
			
			* 3 upper secondary
			egen school_3 = rowtotal(r701d_k2 r701d_k3 r701e_k2 r701e_k3) // banyaknya sekolah
			egen school_distance_3 = rowmin(r701d_k4 r701e_k4)
			
			gen hospital = r704a_k2 == "1"
			gen hospital_distance = r704a_k4
			gen health_center = inlist("1",r704a_k2, r704b_k2, r704c_k2, r704d_k2, r704e_k2)
			replace health_center = 1 if inlist("1", r704f_k2, r704g_k2, r704h_k2, r704i_k2, r704j_k2, r704k_k2)
			egen health_staff = rowtotal(r706a1 r706a2 r706b r706d)
			
			gen poor_hh = r711a
			tab r1001a, gen(transport_)
			tab r1001b1, gen(road_type_)
			
			gen central_distance = r1002b_k2
			gen central_duration = r1002b_k3
			tab r1005b, gen(phone_signal_)
			
			keep year province district hamlet village *_name market_* hh* disaster* school* hospital hospital* health* poor* transport* road_type* central* phone*
			
		} 
		
		replace school_distance_0 = 0 if school_distance_0 == .
		replace school_distance_1 = 0 if school_distance_1 == .
		replace school_distance_2 = 0 if school_distance_2 == .
		replace school_distance_3 = 0 if school_distance_3 == .
		replace hospital_distance = 0 if hospital_distance == .
		replace central_distance = 0 if central_distance == .
		
		save "$temp/podes-`y'.dta", replace
}

use "$temp/podes-2008.dta", clear
drop if merge_podes08 != 3 // unmerged are all non-java

append using "$temp/podes-2014.dta", force

collapse (mean) market_* school_distance_? hospital_distance transport_? road_type_? central_* phone_signal_? disaster_* (sum) hh_PLNelectricity school_? health_staff health_center poor_hh , by(province province_name district district_name hamlet hamlet_name year)

rename province_name nmprov
rename district_name nmkab
rename hamlet_name nmkec
rename province idprov 
rename district idkab
rename hamlet idkec

destring idprov idkab idkec, replace
replace year = 2007 if year == 2008
save "$final/podes-combine.dta", replace

****************************
* DISTRICT IN NUMBERS
****************************

import excel "/$raw/3 District in numbers/xls/district in numbers.xlsx", sheet("2008") firstrow allstring clear

	gen idprov = substr(code,1,2)
	gen idkab = substr(code,3,2)
	destring expenditurepercap lifeexpectancy literacyrate lowersecondary_school lowersecondary_student lowersecondary_teacher pop_density population povertyrate primary_school primary_student primary_teacher province_name schoolage_13_15 schoolage_16_18 schoolage_19_24 schoolage_7_12 schoolduration uppersecondary_school uppersecondary_student uppersecondary_teacher, replace
	gen year = 2008
	rename province_name nmprov
	rename district_name nmkab
	destring idprov idkab, replace
	save "$final/innumbers-combine.dta", replace
	
merge 1:m idprov idkab using "$final/podes-combine.dta"
	
save "$final/hamletdistrict-level-data.dta", replace	
