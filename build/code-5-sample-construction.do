* ******************************************************************************
* PROGRAM: PAPER 1
* PROGRAMMER: Lolita Moorena
* PURPOSE: SAMPLE CONSTRUCTION
* DATE CREATED: 13 April 2023
* LATEST MODIFICATION: -
* ******************************************************************************

* install commands
// ssc install geodist, replace

* ******************************************************************************
* SAMPLE CONSTRUCTION FOR TWO PERIOD DID
* ******************************************************************************

* CREATE LIST OF KECAMATAN NAMES FOR PYTHON
	use "$input/ifls-panel-all-label.dta", clear

	drop if nmkec==""

	keep nmprov nmkab nmkec

	duplicates drop nmprov nmkab nmkec, force

	g kantor="Kantor Kecamatan"

	forval i = 1/3 {
		g space_`i'=" "
	}

	egen kec_full=concat(kantor space_1 nmkec space_2 nmkab space_3 nmprov)
	replace kec_full=strproper(kec_full)

	drop space* kantor

	export excel "$input/kecamatan_names.xlsx", replace first(var)

* CALCULATE GEODISTANCE 
	import excel "$input/kecamatan_names_geocode.xlsx", first clear
	drop A

	g lat_merapi=-7.5407175
	g long_merapi=110.4457241

	g lat_kelud=-7.935
	g long_kelud=112.3138889

	g lat_galunggung=-7.266666699999999
	g long_galunggung=108.0716667

	g lat_raung=-8.1258333
	g long_raung=114.0458333

	foreach x in merapi kelud galunggung raung {
		geodist lat_`x' long_`x' latitude longitude, gen(`x'_distance)
		la var `x'_distance "Distance of kecamatan to mount `x' in KM"
	}

	merge 1:m nmprov nmkab nmkec using "$input/ifls-panel-all-label.dta", nogen
	save "$input/ifls-panel-all-geocode.dta", replace 

* SAMPLE CONSTRUCTION FOR TWO PERIOD DID
	loc m2010 "merapi"
	loc m2013 "kelud"

	foreach j of numlist 2010 2013 {
		use "$input/ifls-panel-all-geocode.dta", clear 

		* Open log
		capture log close
		log using "$log\sample construction_`m`j''.smcl", replace

		di as res "initial observation count (`j')"
		count

		di as res "shrink dataset to age-appropiate sample (`j')"
		keep if inrange(age,6,19)
		count
		
		di as res "keeping only those enrolled at school in `j'"
		keep if enrolled_`j'==1
		count
		
		di as res "drop if enrolled in adult education (kejar paket), school for disabled, or 'others' type of school"
		drop if (exclude_sd==1&enrolled_sd_`j'==1)|(exclude_smp==1&enrolled_smp_`j'==1)|(exclude_sma==1&enrolled_sma_`j'==1)
		count

		* Calculation of potential treatment and control units
		foreach x of numlist 120 100 80 60 {
			foreach z in merapi kelud galunggung raung {
				g radius_`z'_`x'=`z'_distance<=`x'
			}
			g treat_ml_`x'=2 if radius_kelud_`x'==1
			replace treat_ml_`x'=1 if radius_merapi_`x'==1
			replace treat_ml_`x'=3 if radius_galunggung_`x'==1|radius_raung_`x'==1
			la var treat_ml_`x' "Multiple treatment status under radius `x' KM to mountain peak"
			
			g treat_bi_`x'=1 if inlist(treat_ml_`x',1,2)
			replace treat_bi_`x'=0 if treat_ml_`x'==3
			la var treat_bi_`x' "Binary treatment status under radius `x' KM to mountain peak"
		}
		
		* label treatment variable
		la def treat_ml 1 "1 Treatment Merapi" 2 "2 Treatment Kelud" 3 "3 Control Galunggung-Raung"
		la def treat_bi 1 "1 Treatment Merapi-Kelud" 0 "0 Control Galunggung-Raung"
		foreach x in ml bi {
			la val treat_`x'_* treat_`x'
		}

		di as res "shrink dataset to potential sample only (`j')"
		if `j'==2010 {
			keep if inlist(1,radius_merapi_120,radius_galunggung_120,radius_raung_120) 
			count
			
			foreach i of numlist 120 100 80 60 {
				foreach y in kelud galunggung raung {
					qui count if radius_merapi_`i'==1 & radius_`y'_`i'==1
					if `r(N)'>0 {
						tab radius_merapi_`i' radius_`y'_`i'
						tab1 treat_ml_`i' treat_bi_`i' if radius_merapi_`i'==1 & radius_`y'_`i'==1
						tab nmkab if radius_merapi_`i'==1 & radius_`y'_`i'==1
					}	
				}
			}
		}
		else if `j'==2013 {
			keep if inlist(1,radius_kelud_120,radius_galunggung_120,radius_raung_120) 
			drop if radius_merapi_120==1 & radius_kelud_120==1
			count
			
			* check district of kelud treatment
			tab nmkab if treat_ml_120==2
			tab nmkec if treat_ml_120==2 & nmkab=="PASURUAN"
			tab idkab if treat_ml_120==2 & nmkab=="PROBOLINGGO"

			foreach i of numlist 120 100 80 60 {
				foreach y in galunggung raung {
					qui count if radius_kelud_`i'==1 & radius_`y'_`i'==1
					if `r(N)'>0 {
						tab radius_kelud_`i' radius_`y'_`i'
						tab1 treat_ml_`i' treat_bi_`i' if radius_kelud_`i'==1 & radius_`y'_`i'==1
						tab nmkab if radius_kelud_`i'==1 & radius_`y'_`i'==1
					}	
				}
				* correcting for regions untreated by kelud 
				replace treat_ml_`i'=. if treat_ml_`i'==2 & inlist(nmkab,"SITUBONDO","BONDOWOSO","JEMBER","BANYUWANGI")
				replace treat_ml_`i'=. if treat_ml_`i'==2 & nmkab=="PASURUAN" & nmkec~="PANDAAN"
				replace treat_ml_`i'=. if treat_ml_`i'==2 & nmkab=="PROBOLINGGO" & idkab<70
				
				replace treat_bi_`i'=. if treat_bi_`i'==1 & inlist(nmkab,"SITUBONDO","BONDOWOSO","JEMBER","BANYUWANGI")
				replace treat_bi_`i'=. if treat_bi_`i'==1 & nmkab=="PASURUAN" & nmkec~="PANDAAN"
				replace treat_bi_`i'=. if treat_bi_`i'==1 & nmkab=="PROBOLINGGO" & idkab<70
			}
		}

		di as res "dropping non-panel observations (`j')"
		duplicates tag pidlink, gen(panel)
		drop if panel==0
		drop panel
		count		
		
		* generate variable to indicate sample set
		loc v2010=1
		loc v2013=2
		
		g estsample=`v`j''
		
		la def sset 1 "1 Merapi estimation sample" 2 "2 Kelud estimation sample"
		la val estsample sset

		* save data
		save "$input/ifls-panel-sample_`m`j''.dta", replace

		* close log
		log close 

		estpost tab treat_bi_120
		eststo `m`j''
	}

	esttab merapi kelud using "$tables\samplesize_prematching.tex", replace noobs nonum ///
	title("Pre-matching sample size") coeflab(0 "Control" 1 "Treatment") ///
	mtitle("Merapi estimation" "Kelud estimation") nonotes b(%12.0fc)
	
	esttab merapi kelud using "$tables\samplesize_prematching.rtf", replace noobs nonum ///
	title("Pre-matching sample size") coeflab(0 "Control" 1 "Treatment") ///
	mtitle("Merapi estimation" "Kelud estimation") nonotes b(%12.0fc)

* ******************************************************************************
* SAMPLE CONSTRUCTION FOR MULTIPLE PERIOD DID
* ******************************************************************************

* CREATE LIST OF KECAMATAN NAMES FOR PYTHON
	use "$input/ifls-panel-all-label.dta", clear

	keep if year==2014

	keep provnm20* kabnm20* kecnm20* provid20* kabid20* kecid20* hhid id 
	foreach x in father mother hhhead hhhead_spouse oldestman oldestwoman {
		drop prov*20*_`x' kab*20*_`x' kec*20*_`x'
	}
	drop *2006

	reshape long provnm kabnm kecnm provid kabid kecid, i(hhid id) j(year)
	drop if kecnm==""
	drop hhid id year 

	duplicates drop provid kabid kecid, force

	g kantor="Kantor Kecamatan"

	forval i = 1/3 {
		g space_`i'=" "
	}

	egen kec_full=concat(kantor space_1 kecnm space_2 kabnm space_3 provnm)
	replace kec_full=strproper(kec_full)

	drop space* kantor

	export excel "$input/kecamatan_names_multiperiod.xlsx", replace first(var)

* CALCULATE GEODISTANCE 
	import excel "$input/kecamatan_names_multiperiod_geocode.xlsx", first clear
	drop A

	g lat_merapi=-7.5407175
	g long_merapi=110.4457241

	g lat_kelud=-7.935
	g long_kelud=112.3138889

	g lat_galunggung=-7.266666699999999
	g long_galunggung=108.0716667

	g lat_raung=-8.1258333
	g long_raung=114.0458333

	foreach x in merapi kelud galunggung raung {
		geodist lat_`x' long_`x' latitude longitude, gen(`x'_distance)
		la var `x'_distance "Distance of kecamatan to mount `x' in KM"
	}

	save "$input/kecamatan_multiperiod.dta", replace

* SAMPLE CONSTRUCTION FOR MULTIPLE PERIOD DID
	use "$input/ifls-panel-all-label.dta", clear
	
	keep if year==2014

	keep hhid id pidlink enrolled* exclude* workstat* age20* prov*20* kab*20* kec*20*
	drop *hhhead* *oldest* workstat2007-workstat2014 *2006 
	foreach x in father mother {
		drop prov*20*_`x' kab*20*_`x' kec*20*_`x'
		forval i=2007/2014 {
			foreach y in workstat age {
				ren `y'`i'_`x' `y'`x'`i'
			}
		}
	}

	forval i=2007/2014 {
		clonevar enrolled`i'=enrolled_`i' 
		foreach x in sd smp sma {
			clonevar enrolled`x'`i'=enrolled_`x'_`i' 
		}
	}

	loc longvar provid provnm kabid kabnm kecid kecnm ///
	age agefather agemother workstatfather workstatmother ///
	enrolled enrolledsd enrolledsmp enrolledsma
	reshape long `longvar', i(hhid id) j(year)

	merge m:1 provid kabid kecid using "$input/kecamatan_multiperiod.dta", nogen
	
	* calculation of potential treatment and control units
	foreach x of numlist 120 100 80 60 {
		foreach z in kelud merapi galunggung raung {
			g radius_`z'_`x'=`z'_distance<=`x'
		}
		g treat_ml_`x'=2 if radius_kelud_`x'==1
		replace treat_ml_`x'=1 if radius_merapi_`x'==1
		replace treat_ml_`x'=3 if inlist(1,radius_galunggung_`x',radius_raung_`x')
		la var treat_ml_`x' "Multiple treatment status under radius `x' KM to mountain peak"
		
		g treat_bi_`x'=1 if inlist(treat_ml_`x',1,2)
		replace treat_bi_`x'=0 if treat_ml_`x'==3
		la var treat_bi_`x' "Binary treatment status under radius `x' KM to mountain peak"
	}
	
	* label treatment variable
	la def treat_ml 1 "1 Treatment Merapi" 2 "2 Treatment Kelud" 3 "3 Control Galunggung-Raung"
	la def treat_bi 1 "1 Treatment Merapi/Kelud" 0 "0 Control Galunggung-Raung"
	foreach x in ml bi {
		la val treat_`x'_* treat_`x'
	}

	foreach y in father mother {
		qui levelsof workstat`y'
		foreach x of numlist `r(levels)' {
			g workstat`y'_`x'=workstat`y'==`x'
		}
	}
	
	* save data
	save "$input/ifls-panel-multiperiod-all.dta", replace 
	
	* data for each estimation
	loc m2010 "merapi"
	loc m2013 "kelud"
	
	foreach x of numlist 2010 2013 {
		use "$input/ifls-panel-multiperiod-all.dta", clear
		
		* filter 1: school age children
		keep if inrange(age,6,19)
		
		* filter 2: enrolled during eruption
		keep if enrolled_`x'==1
		
		* filter 3: not in SLB/Kejar Paket/others 
		drop if (exclude_sd==1&enrolled_sd_`x'==1)|(exclude_smp==1&enrolled_smp_`x'==1)|(exclude_sma==1&enrolled_sma_`x'==1)
		
		* filter 4: within 120km radius of the volcano
		if `x'==2010 {
			keep if inlist(1,radius_merapi_120,radius_kelud_120,radius_galunggung_120,radius_raung_120)		
			
			foreach i of numlist 120 100 80 60 {
				foreach y in kelud galunggung raung {
					qui count if radius_merapi_`i'==1 & radius_`y'_`i'==1
					if `r(N)'>0 {
						tab radius_merapi_`i' radius_`y'_`i'
						tab1 treat_ml_`i' treat_bi_`i' if radius_merapi_`i'==1 & radius_`y'_`i'==1
						tab kabnm if radius_merapi_`i'==1 & radius_`y'_`i'==1
					}	
				}
				g treat_merapi_`i'=year>2009 & treat_ml_`i'==1
			}
		}
		else if `x'==2013 {
			keep if inlist(1,radius_kelud_120,radius_galunggung_120,radius_raung_120)
			drop if radius_merapi_120==1 & radius_kelud_120==1
			
			foreach i of numlist 120 100 80 60 {
				foreach y in galunggung raung {
					qui count if radius_kelud_`i'==1 & radius_`y'_`i'==1
					if `r(N)'>0 {
						tab radius_kelud_`i' radius_`y'_`i'
						tab1 treat_ml_`i' treat_bi_`i' if radius_kelud_`i'==1 & radius_`y'_`i'==1
						tab kabnm if radius_kelud_`i'==1 & radius_`y'_`i'==1
					}	
				}
				g treat_kelud_`i'=year==2014 & treat_ml_`i'==2
			}
		}
		
		foreach i of numlist 120 100 80 60 {
			dis as res "correcting treatment status for kelud catchment who actually did not get treatment"
			replace treat_ml_`i'=. if treat_ml_`i'==2 & inlist(kabnm,"SITUBONDO","BONDOWOSO","JEMBER","BANYUWANGI")
			replace treat_ml_`i'=. if treat_ml_`i'==2 & kabnm=="PASURUAN" & kecnm~="PANDAAN"
			replace treat_ml_`i'=. if treat_ml_`i'==2 & kabnm=="PROBOLINGGO" & kabid<70
			
			replace treat_bi_`i'=. if treat_bi_`i'==1 & inlist(kabnm,"SITUBONDO","BONDOWOSO","JEMBER","BANYUWANGI")
			replace treat_bi_`i'=. if treat_bi_`i'==1 & kabnm=="PASURUAN" & kecnm~="PANDAAN"
			replace treat_bi_`i'=. if treat_bi_`i'==1 & kabnm=="PROBOLINGGO" & kabid<70	
		}
		
		g distance=merapi_distance if treat_ml_120==1
		replace distance=kelud_distance if treat_ml_120==2
		replace distance=galunggung_distance if treat_ml_120==3 & galunggung_distance<raung_distance
		replace distance=raung_distance if treat_ml_120==3 & galunggung_distance>raung_distance
	
		egen district = group(provid kabid)
		egen hamlet = group(provid kabid kecid)
		encode pidlink, gen(panelid)
		
		* unused vars
		drop enrolled_* exclude*
		
		* generate variable to indicate sample set
		loc v2010=1
		loc v2013=2
		
		g estsample=`v`x''
		
		la def sset 1 "1 Merapi estimation sample" 2 "2 Kelud estimation sample"
		la val estsample sset
		
		* save data
		save "$final/ifls-panel-multiperiod-`m`x''.dta", replace 
	}
