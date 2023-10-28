** COMBINE ALL DATASETS *******************************************************
foreach mount in "merapi" "kelud" {
	use "$input/ifls-panel-sample_`mount'.dta", clear
	duplicates tag pidlink year, gen(dup)
	drop if dup > 0 & pwt_panel == .
	gen commid = commid07 if year == 2007
	replace commid = commid14 if year == 2014
		
tempfile original
save `original', replace

	* combine with ifls community level data
	use "$input/get-ifls-4-comm.dta", clear
	append using "$input/get-ifls-5-comm.dta"
	gen commid = commid07 if year == 2007
	replace commid = commid14 if year == 2014
	
	merge 1:m commid year using `original'
	drop if _m == 1
	drop _m
	
* combine with statistics of industry data
	merge m:1 idprov idkab year using "$input/get-industry-statistics.dta"
	drop if _m == 2
	drop _m
	
* combine with podes data
	* edit some
	replace nmkec = "CIMENYAN" if idprov == 32 & idkab == 4 & idkec == 310
	replace nmkec = "KRAMATMULYA" if idprov == 32 & idkab == 8 & idkec == 150
	replace idkec = 111 if idprov == 32 & idkab == 9 & nmkec == "TALUN"
	replace nmkec = "KEDAWUNG" if idprov == 32 & idkab == 9 & idkec == 161
	replace idkec = 162 if idprov == 32 & idkab == 9 & nmkec == "KEDAWUNG"
	replace idkec = 171 if idprov == 32 & idkab == 9 & nmkec == "GUNUNGJATI"
	replace nmkec = "PONDOK SALAM" if idprov == 32 & idkab == 14 & idkec == 91
	replace idkec = 61 if idprov == 32 & idkab == 16 & nmkec == "CIKARANG UTARA"
	replace nmkec = "BOGOR SELATAN" if idprov == 32 & idkab == 71 & idkec == 10
	replace nmkec = "BOGOR TIMUR" if idprov == 32 & idkab == 71 & idkec == 20
	replace nmkec = "BOGOR UTARA" if idprov == 32 & idkab == 71 & idkec == 30
	replace nmkec = "BOGOR TENGAH" if idprov == 32 & idkab == 71 & idkec == 40
	replace nmkec = "BOGOR BARAT" if idprov == 32 & idkab == 71 & idkec == 50
	replace nmkab = "KOTA CIMAHI" if idprov == 32 & idkab == 77 & idkec == 30
	replace nmkab = "KOTA CIMAHI" if idprov == 32 & idkab == 77 & idkec == 10
	replace nmkab = "KOTA TASIKMALAYA" if idprov == 32 & idkab == 78 & idkec == 30
	replace nmkab = "KOTA TASIKMALAYA" if idprov == 32 & idkab == 78 & idkec == 60
	replace nmkab = "KOTA TASIKMALAYA" if idprov == 32 & idkab == 78 & idkec == 50
	replace nmkec = "MERTOYUDAN" if idprov == 33 & idkab == 8 & idkec == 110
	replace nmkec = "BANDUNGAN" if idprov == 33 & idkab == 22 & idkec == 101
	replace nmkab = "KOTA MOJOKERTO" if idprov == 35 & idkab == 76 & idkec == 20
	replace nmkec = "TEGALSARI" if idprov == 35 & idkab == 78 & idkec == 180
	replace nmkec = "SUKO MANUNGGAL" if idprov == 35 & idkab == 78 & idkec == 160
	replace nmkec = "LAKARSANTRI" if idprov == 35 & idkab == 78 & idkec == 140
	replace nmkec = "SAMBIKEREP" if idprov == 35 & idkab == 78 & idkec == 140
	replace idkab = 73 if nmprov == "BANTEN" & nmkab == "SERANG" & nmkec == "SERANG"
	replace idkec = 40 if nmprov == "BANTEN" & nmkab == "SERANG" & nmkec == "SERANG"
	replace idkab = 73 if nmprov == "BANTEN" & nmkab == "SERANG" & nmkec == "CIPOCOK JAYA"
	replace idkec = 30 if nmprov == "BANTEN" & nmkab == "SERANG" & nmkec == "CIPOCOK JAYA"
	replace idkab = 22 if nmprov == "JAWA TIMUR" & nmkab == "KEDIRI" & nmkec == "NGASEM" & year == 2007
	replace idkec = 190 if nmprov == "JAWA TIMUR" & nmkab == "KEDIRI" & nmkec == "NGASEM" & year == 2007
	
	merge m:1 idprov idkab idkec nmprov nmkab nmkec year using "$final/podes-combine.dta"
	drop if _m == 2 
	drop _m
	
	merge m:1 idprov idkab idkec year using "$final/podes-combine.dta"
	drop if _m == 2 
	drop _m

save "$final/ifls-`mount'.dta", replace
}
