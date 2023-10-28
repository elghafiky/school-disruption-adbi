capture log close
clear all
set more off

* import data and save as dta
import excel "$vol\indonesia volcano eruption history 25-03-2023.xlsx", clear first
replace VolcanoName="Sumbing Central Sumatra" if VolcanoName=="Sumbing" & inlist(StartDate,"1909 Jun 3","1921 May 23")
replace VolcanoName="Sumbing Central Java" if VolcanoName=="Sumbing"
save "$vol\indonesia volcano eruption history 25-03-2023.dta", replace

import excel "$vol\indonesia holocene volcanoes.xlsx", clear first
replace VolcanoName="Sumbing Central Sumatra" if VolcanoName=="Sumbing" & LastEruption=="1921 CE"
replace VolcanoName="Sumbing Central Java" if VolcanoName=="Sumbing"
save "$vol\indonesia holocene volcanoes.dta", replace

* merge volcano list with eruptive history
merge 1:m VolcanoName using "$vol\indonesia volcano eruption history 25-03-2023.dta"
tab LastEruption if _merge<3

* indicate if java volcano
g java=regexm(Location,"Java")

* create eruption year variable
split StartDate
replace StartDate1=subinstr(StartDate1,"[","",.)
replace StartDate1=subinstr(StartDate1,"]","",.)
destring StartDate1, replace 
ren StartDate1 eruptyear
drop StartDate2-StartDate9

* indicate if eruption in bce period
g bce=regexm(StartDate,"BC") 

* volcanoes in java with at least VEI 4 eruption
tab VolcanoName VEI if VEI>3 & VEI<. & java==1

* save data
save "$vol\indonesia volcanoes.dta", replace 
