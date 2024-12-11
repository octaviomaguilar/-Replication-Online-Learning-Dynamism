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
*load BDS firm age data
import delimited using "$bds/bds2021_sec_fa.csv", clear

/* Cleaning */
rename sector naics

*1.1: set sample restriction
drop if year < 2013

*1.2: create firm size groups
gen fageg = .
replace fageg = 0 if fage == "a) 0"
replace fageg = 1 if fage == "b) 1"
replace fageg = 2 if fage == "c) 2"
replace fageg = 3 if fage == "d) 3"
replace fageg = 4 if fage == "e) 4"
replace fageg = 5 if fage == "f) 5"
replace fageg = 6 if fage == "g) 6 to 10"
replace fageg = 7 if fage == "h) 11 to 15"
replace fageg = 8 if fage == "i) 16 to 20"
replace fageg = 9 if fage == "j) 21 to 25"
replace fageg = 10 if fage == "k) 26+"
replace fageg = 11 if fage == "l) Left Censored"

foreach x in job_creation_rate job_destruction_rate net_job_creation_rate reallocation_rate emp job_destruction job_creation{
drop if `x' == "D" | `x' =="X" | `x' == "N"
destring `x', replace
}

*1.3: calculate total employment by year-industry:
bys naics year: egen tot_emp = total(emp)

*1.4: calculate employment share 
bys naics year fageg: gen emp_share = emp/tot_emp

*1.5: keep variables of interest
keep year naics emp job_creation job_creation_rate net_job_creation_rate job_destruction job_destruction_rate reallocation_rate fageg tot_emp emp_share

*1.6: merge in 2-digit NAICS bartik measure 
merge m:1 naics using "$data/bartik/bartik_naics2.dta", keep(3) nogen
rename naics naics2

*1.7: prepare data for event study 
gen t = year

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

save "$bds/bds2021_sec_fa_trimmed.dta", replace
*********
***(4)***
*********
*figure 4 panel D: 
use "$bds/bds2021_sec_fa_trimmed.dta", clear

keep if fageg == 11
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
				graph export "$figures/figure4_panelD.eps", replace
			restore
