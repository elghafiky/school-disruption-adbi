capture log close

// ssc install coefplot, replace
// ssc install pretrends, replace

* Event study
use "$final/ifls-panel-multiperiod-merapi.dta", replace 

* panelize data
drop if treat_ml_120==2
duplicates tag pidlink, gen(panel)
qui sum panel
keep if panel==`r(max)'
drop panel 

tempfile merapi
save `merapi', replace 

use "$final/ifls-panel-multiperiod-kelud.dta", clear

* panelize data
duplicates tag pidlink, gen(panel)
qui sum panel
keep if panel==`r(max)'
drop panel 

append using `merapi'

save "$final/ifls-multiperiod-stacked.dta", replace

clonevar _treated=treat_bi_120

estpost tab _treated
eststo sampsi

esttab sampsi using "$tables\samplesize_eventstudy.tex", replace noobs nonum ///
title("Event study sample size") coeflab(0 "Control" 1 "Treatment") nonotes b(%12.0fc)

esttab sampsi using "$tables\samplesize_eventstudy.rtf", replace noobs nonum ///
title("Event study sample size") coeflab(0 "Control" 1 "Treatment") nonotes b(%12.0fc)
	
	* rt for relative timing
	gen rt = .
		replace rt = year - 2010 if estsample == 1 
		replace rt = year - 2014 if estsample == 2 
	
	gen year_rt = rt + 8
	
	* leads and lags
	local var rt
		forval t=1/7 {
			local time = -1 * `t'
			gen `var'_L`t' = 0
			replace `var'_L`t' =  distance if rt == `time' & _treated == 1
		}
		forval t=0/4 {
			gen `var'_P`t' = 0
			replace `var'_P`t' = distance if rt == `t' & _treated == 1
		}
		
	encode pidlink, gen(pidlinkx)	
	egen group_prov = group(estsample provid)
	egen group_district = group(estsample district)
	
	areg enrolled rt_L7 rt_L6 rt_L5 rt_L4 rt_L3 rt_L2 rt_P0-rt_P4 c.distance##i._treated i.workstatfather i.workstatmother latitude longitude i.year_rt##i.provid i.district age agefather agemother, robust cluster(group_district) absorb(pidlinkx)
	eststo leads_lags
	
coefplot leads_lags, baselevel omitted ///
	keep(rt_L7 rt_L6 rt_L5 rt_L4 rt_L3 rt_L2 rt_P0 rt_P1 rt_P2 rt_P3 rt_P4) ///
vertical title( "") coeflabels(rt_L7="-7" rt_L6="-6" rt_L5="-5" rt_L4="-4" rt_L3="-3" rt_L2="-2" rt_P0="0" rt_P1="1" rt_P2="2" rt_P3="3" rt_P4="4") ///
         xtitle("Relative timing") ///
		 xscale(titlegap(2))  yline(0, lcolor(black)) xline(7, lpattern(dash)) ///
	graphregion(fcolor(white) lcolor(white) lwidth(vvvthin) ///
	ifcolor(white) ilcolor(white) ilwidth(vvvthin)) ///
	mlabel(cond(@pval<.01, string(@b,"%9.4f") + "***", ///
cond(@pval<.05, string(@b,"%9.4f") + "**", ///
cond(@pval<.10, string(@b,"%9.4f") + "*", ///
string(@pval,"%9.3f"))))) ///
note("coefficient shown alongside markers" "* p<0.10, ** p<0.05, *** p<0.01")

gr export "$figures/event analysis.png", replace		

* Simulation to check the power
areg enrolled_ rt_L7 rt_L6 rt_L5 rt_L4 rt_L3 rt_L2 rt_P0-rt_P4 c.distance##i._treated i.workstat_father_ i.workstat_mother_ latitude longitude i.year_rt##i.idprov i.district age age_father_ age_mother_, robust cluster(group_district) absorb(pidlinkx)
local limit = r(table)[1,1] + r(table)[2,1] + r(table)[3,1] + r(table)[4,1] + r(table)[5,1] + r(table)[6,1]
local counter = 1
mat a=J(1000,3,.)
forval i=0.5(0.01)0.9 {
	qui areg enrolled_ rt_L7 rt_L6 rt_L5 rt_L4 rt_L3 rt_L2 rt_P0-rt_P4 c.distance##i._treated i.workstat_father_ i.workstat_mother_ latitude longitude i.year_rt##i.idprov i.district age age_father_ age_mother_, robust cluster(group_district) absorb(pidlinkx)
	pretrends power `i', pre(1/6) post(7/11)
	mat a[`counter',1]=`i'
	mat a[`counter',2]=`r(slope)'
	mat a[`counter',3]=`limit'
	local counter = `counter' + 1
}
