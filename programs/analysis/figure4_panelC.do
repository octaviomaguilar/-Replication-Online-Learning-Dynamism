cap cls
clear all
set more off

global home = "/mq/scratch/m1oma00/oma_projects/replication_online_productivity_oma_final"
global data "$home/data"
global cps "$home/data/cps"
global oes "$home/data/oes"
global ces "$data/ces"
global bds "$data/bds"
global figures "$home/figures"

*********
***(1)***
*********
*load BDS firm size data
import delimited using "$bds/bds2021_sec_fz.csv", clear

/* Cleaning */
rename sector naics

*1.1: set sample restriction
drop if year < 2013

*1.2: create firm size groups
gen fsizeg = .
replace fsizeg = 1 if fsize == "a) 1 to 4"
replace fsizeg = 2 if fsize == "b) 5 to 9"
replace fsizeg = 3 if fsize == "c) 10 to 19"
replace fsizeg = 4 if fsize == "d) 20 to 99"
replace fsizeg = 5 if fsize == "e) 100 to 499"
replace fsizeg = 6 if fsize == "f) 500 to 999"
replace fsizeg = 7 if fsize == "g) 1000 to 2499"
replace fsizeg = 8 if fsize == "h) 2500 to 4999"
replace fsizeg = 9 if fsize == "i) 5000 to 9999"
replace fsizeg = 10 if fsize == "j) 10000+"

*1.3: calculate total employment by year-industry:
bys naics year: egen tot_emp = total(emp)

*1.4: calculate employment share 
bys naics year fsizeg: gen emp_share = emp/tot_emp

*1.5: keep variables of interest
keep year naics emp job_creation job_creation_rate net_job_creation_rate job_destruction job_destruction_rate reallocation_rate fsizeg tot_emp emp_share

*1.6: merge in 2-digit NAICS bartik measure 
merge m:1 naics using "$data/bartik/bartik_naics2.dta", keep(3) nogen
rename naics naics2
gen t = year

*1.7: prepare data for event study 
local begin = 2013
local end = 2021
local num = `end'-`begin'+1

local base = 2019

forval i = 1/`num' {
	gen z`i' = t-`begin'+1 == `i'
}
local f = `base' - `begin' + 1
replace z`f' = 0

keep if t >= `begin'

forval i = 1/`num' {
	gen bartik_z`i' = bartik*z`i'
}

gen post = t >= `base'

egen Inaics2 = group(naics2)

save "$bds/bds2021_sec_fz_trimmed.dta", replace

*********
***(4)***
*********
*figure 4 panel C: 
use "$bds/bds2021_sec_fz_trimmed.dta", clear

keep if fsizeg == 10
reghdfe emp_share bartik_z*, absorb(i.Inaics2 i.t) vce(cluster t Inaics2)

tempfile f
parmest, saving(`f', replace)
		preserve
			use `f', clear
			
			gen time = 2013 + _n -1
			format time %ty

			keep if strpos(parm,"bartik")

	twoway (rarea min95 max95 time, fcolor(Blueish-gray8*0.15) lcolor(purple*0.15) lw(none) lpattern(solid)) ///
	       (connected estimate time) ///
	       (scatter estimate time, lwidth(thick) mcolor(black) msize(medsmall)), ///
	       xtitle("") ytitle("Employment Share") graphregion(color(white)) ///
	       yline(0, lcolor(black) lwidth(thin)) xline(2019, lcolor(red)) legend(off) ///
	       ylabel(, format(%9.2f))
	       
			graph export "$figures/figure4_panelC.eps", replace
			restore

