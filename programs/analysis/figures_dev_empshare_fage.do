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
*load QWI firm size data:
use "$data/bartik/bartik_state_naics4_fage.dta", clear
gen t = time 
format t %tq

*1.1: reshape the data:
keep t time statefips naics4 firmage emp frm* hir* sep* bartik

reshape wide emp frm* hir* sep*, i(t naics4 bartik statefips) j(firmage)

*1.2: prepare data for event study:
*228 is 2017q1
*239 is 2019q4
*251 is 2022q4
*253 is 2023q2

local begin = 228
local end = 253
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

*1.4: create outcome variables
forval i = 0/5 {
	gen emp_share`i' = emp`i'/emp0
}

preserve
	keep if year == 2019
	keep naics4 statefips qtr emp* emp_share*
	forval i = 0/5 {
		foreach x in emp emp_share {
			rename `x'`i' `x'`i'_2019
		}
	}
	
	tempfile f2019
	save `f2019', replace
restore
merge m:1 naics4 statefips qtr using `f2019', nogen
forval i = 0/5 {
	gen dev_emp`i' = emp`i'/emp`i'_2019 - 1
	gen dev_emp_share`i' = emp_share`i' - emp_share`i'_2019
}

*Block 2 produces figure 4 panel B
*Block 3-3.1 produces figure 5 Panels C and D. 

*******
**(2)**
*******
*Figure 4 Panel B: Deviation in employment share for firms that are aged 11+
qui reghdfe dev_emp_share5 ib239.t##c.bartik, absorb(i.Istate i.Inaics4 i.Inaics2_time) vce(cluster Inaics4 time)

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
	       xtitle("") ytitle("Deviation in Employment Share") graphregion(color(white)) ///
	       yline(0, lcolor(black) lwidth(thin)) xline(240, lcolor(red)) legend(off) ///
	       ylabel(, format(%9.2f))
		restore
		graph export "$figures/figure4_panelB.eps", replace
		
*******
**(3)**
*******
*Figure 5 Panel C: Deviation in employment share for firms that are aged 2-3
qui reghdfe dev_emp_share2 ib239.t##c.bartik, absorb(i.Istate i.Inaics4 i.Inaics2_time) vce(cluster Inaics4 time)

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
	       xtitle("") ytitle("Deviation in Employment Share") graphregion(color(white)) ///
	       yline(0, lcolor(black) lwidth(thin)) xline(240, lcolor(red)) legend(off) ///
	       ylabel(, format(%9.2f))
		restore
		graph export "$figures/figure5_panelC.eps", replace

*******
**(3)**
*******
*Figure 5 Panel D: Deviation in employment share for firms that are aged 6-10
qui reghdfe dev_emp_share4 ib239.t##c.bartik, absorb(i.Istate i.Inaics4 i.Inaics2_time) vce(cluster Inaics4 time)

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
	       xtitle("") ytitle("Deviation in Employment Share") graphregion(color(white)) ///
	       yline(0, lcolor(black) lwidth(thin)) xline(240, lcolor(red)) legend(off) ///
	       ylabel(, format(%9.2f))
		restore
		graph export "$figures/figure5_panelD.eps", replace
