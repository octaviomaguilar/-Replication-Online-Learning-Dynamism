cap cls
clear all
set more off
*ssc install mdesc
*ssc install reghdfe
*ssc install ftools
*ssc install parmest

global home = "/mq/scratch/m1oma00/oma_projects/replication_online_productivity_oma_final"
global data "$home/data"
global cps "$home/data/cps"
global oes "$home/data/oes"
global ces "$data/ces"
global bds "$data/bds"
global figures "$home/figures"
global qwi "$data/qwi"

*******
**(1)**
*******
*load QWI data
/*
use "$data/bartik/bartik_qwi_earn_fage.dta", clear
drop earnseps
gen t = time 
format t %tq
keep t time statefips naics4 firmage earn* bartik

*1.1: reshape the data
reshape wide earn*, i(t naics4 bartik statefips) j(firmage)

*1.2: prepare the data for event study
*228 is 2017q1
*239 is 2019q4
*251 is 2022q4
*253 is 2023q2
gen temp = t
drop if temp >254
local begin = 228
local end = 254
local num = `end'-`begin'+1

local base = 239

forval i = 1/`num' {
	gen z`i' = t-`begin'+1 == `i'
}
local f = `base' - `begin' + 1
replace z`f' = 0

keep if t >= `begin'

forval i = 1/`num' {
	gen bartik_z`i' = bartik*z`i'
}


*1.3: create FEs
egen Inaics4 = group(naics4)
gen d = dofq(t)
gen qtr = quarter(d)
gen year = year(d)
egen Istate_qtr = group(statefips time)
egen Istate_yr = group(statefips year)

egen Istate = group(state)
gen naics2 = substr(naics4,1,2)
egen Inaics2_time = group(naics2 time)

/*********************
1.4: INFLATION ADJUST
*********************/
*A191RD3A086NBEA: Gross domestic product (implicit price deflator), Index 2017=100
*/
foreach i of varlist earn* {
replace `i' = `i' *  1 if year == 2017
replace `i' = `i' *   1.02291 if year == 2018
replace `i' = `i' * 1.03979 if year == 2019
replace `i' = `i' *  1.05361 if year == 2020
replace `i' = `i' *  1.10172 if year == 2021
replace `i' = `i' *  1.18026 if year == 2022
replace `i' = `i' *  1.22273 if year == 2023
}

*1.5: create outcome variables
preserve
	keep if year == 2019
	keep naics4 statefips qtr earn*
	forval i = 0/5 {
		foreach x in earnbeg earnhiras earnhirns earns {
			rename `x'`i' `x'`i'_2019
		}
	}
	
	tempfile f2019
	save `f2019', replace
restore
merge m:1 naics4 statefips qtr using `f2019', nogen

*EarnBeg: Average monthly earnings of employees who worked on the first day of the reference quarter. 
*1.6: deviation in earnings relative to pre-pandemic average:
forval i = 0/5 {
	gen dev_earnbeg`i' = earnbeg`i'/earnbeg`i'_2019 - 1

}

*1.7: drop extreme observations (top 1%) for earnings.
forval i = 0/5 {
	drop if dev_earnbeg`i' > 1.10
}

keep dev_earnbeg* Istate Inaics4 Inaics2_time time bartik

save "$data/bartik/bartik_qwi_earn_fage_trimmed.dta", replace
*/
*********
**(2.0)**
*********
use "$data/bartik/bartik_qwi_earn_fage_trimmed.dta", clear
*Figure 6 panel E: deviation in average monthly earnings for firm age groups 2-3. 
qui reghdfe dev_earnbeg2 ib239.t##c.bartik, absorb(i.Istate i.Inaics4 i.Inaics2_time) vce(cluster Inaics4 time)

	tempfile f
	parmest, saving(`f', replace)
		preserve
			use `f', clear
			keep if strpos(parm,".bartik") & strpos(parm,"c")
			
			gen time = substr(parm,1,3)
			destring time, replace
			format time %tq

			*keep if strpos(parm,"bartik")

	twoway (rarea min95 max95 time, fcolor(Blueish-gray8*0.15) lcolor(purple*0.15) lw(none) lpattern(solid)) ///
	       (connected estimate time) ///
	       (scatter estimate time, lwidth(thick) mcolor(black) msize(medsmall)), ///
	       xtitle("") ytitle("Deviation in Average Monthly Earnings") graphregion(color(white)) ///
	       yline(0, lcolor(black) lwidth(thin)) xline(240, lcolor(red)) legend(off) ///
	       ylabel(, format(%9.2f))
		restore
		graph export "$figures/figure6_panelE.eps", replace

*********
**(2.1)**
*********
*Figure 6 panel F: deviation in average monthly earnings for firm age groups 6-10. 
qui reghdfe dev_earnbeg4 ib239.t##c.bartik, absorb(i.Istate i.Inaics4 i.Inaics2_time) vce(cluster Inaics4 time)

	tempfile f
	parmest, saving(`f', replace)
		preserve
			use `f', clear
			keep if strpos(parm,".bartik") & strpos(parm,"c")
			
			gen time = substr(parm,1,3)
			destring time, replace
			format time %tq

			*keep if strpos(parm,"bartik")

	twoway (rarea min95 max95 time, fcolor(Blueish-gray8*0.15) lcolor(purple*0.15) lw(none) lpattern(solid)) ///
	       (connected estimate time) ///
	       (scatter estimate time, lwidth(thick) mcolor(black) msize(medsmall)), ///
	       xtitle("") ytitle("Deviation in Average Monthly Earnings") graphregion(color(white)) ///
	       yline(0, lcolor(black) lwidth(thin)) xline(240, lcolor(red)) legend(off) ///
	       ylabel(, format(%9.2f))
		restore
		graph export "$figures/figure6_panelF.eps", replace

*********
**(2.2)**
*********
*Figure 6 panel G: deviation in average monthly earnings for firm age groups 11+. 
qui reghdfe dev_earnbeg5 ib239.t##c.bartik, absorb(i.Istate i.Inaics4 i.Inaics2_time) vce(cluster Inaics4 time)

	tempfile f
	parmest, saving(`f', replace)
		preserve
			use `f', clear
			keep if strpos(parm,".bartik") & strpos(parm,"c")
			
			gen time = substr(parm,1,3)
			destring time, replace
			format time %tq

			*keep if strpos(parm,"bartik")

	twoway (rarea min95 max95 time, fcolor(Blueish-gray8*0.15) lcolor(purple*0.15) lw(none) lpattern(solid)) ///
	       (connected estimate time) ///
	       (scatter estimate time, lwidth(thick) mcolor(black) msize(medsmall)), ///
	       xtitle("") ytitle("Deviation in Average Monthly Earnings") graphregion(color(white)) ///
	       yline(0, lcolor(black) lwidth(thin)) xline(240, lcolor(red)) legend(off) ///
	       ylabel(, format(%9.2f))
		restore
		graph export "$figures/figure6_panelG.eps", replace
