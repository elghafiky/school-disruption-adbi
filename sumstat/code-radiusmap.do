use "$pod\ina_data_podes.dta", clear

ren (PROVINSI KABKOT KECAMATAN PROVNO KABKOTNO KECNO) (nmprov nmkab nmkec idprov idkab idkec)
destring idprov idkab idkec, replace

tempfile shp
save `shp', replace

use "$final\stacked-analysis.dta", clear

keep if year==2014

collapse (mean) treat_ml_120, by(nmprov nmkab nmkec idprov idkab idkec )

merge 1:m idprov idkab idkec using `shp' 
keep if inrange(idprov,31,36)

spmap treat_ml_120 using "$pod/ina_coordinates_podes.dta", id(id) fcolor(Rainbow) ocolor(none ..) clmethod(unique) /// 
legend(order(1 "Not in sample" 2 "Merapi" 3 "Kelud" 4 "Galunggung-Raung") pos(6) rows(1)) 
graph export "$figures\java map.png", as(png) replace
