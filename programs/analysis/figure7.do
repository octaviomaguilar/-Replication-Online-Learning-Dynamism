cap cls
clear all
set more off

global home = "/mq/scratch/m1oma00/oma_projects/replication_online_productivity_oma_final"
global data "$home/data"
global cps "$home/data/cps"
global oes "$home/data/oes"
global ces "$data/ces"
global bds "$data/bds"
global bls "$data/bls"
global figures "$home/figures"

*******
**(1)**
*******
*load BLS Industry Productivity Data
use "$bls/blsip_naics4_regdata.dta", clear

*1.1: keep variables of interest 
keep year sector naics4 bartik lp* opw* emp*

*1.2: prepare data for event study:
local begin = 2011
local end = 2023
local num = `end'-`begin'+1
keep if year >= `begin' & year <= `end'
local base = 2020

local vlist "lp_lvl opw_lvl emp_lvl"

forval i = 1/`num' {
	gen z`i' = year-`begin'+1 == `i'
}
local f = `base' - `begin' + 1
replace z`f' = 0

*1.3: create main explanatory variable to represent a 1SD increase in the bartik shock
egen mean_bartik = mean(bartik)
gen bartik_dev = bartik-mean_bartik
su bartik_dev, de
local sd = r(sd)
replace bartik_dev = bartik_dev/`sd'

gen ind = sector == "I"

forval i = 1/`num' {
	gen bartik_z`i' = bartik_dev*z`i'
	gen ind_bartik_z`i' = ind*bartik_dev*z`i'
	gen ind_z`i' = ind*z`i'
}

preserve
	keep if year == `base'
	keep naics4 `vlist'
	
	foreach x of varlist `vlist' {
	    rename `x' `x'b
	}
	
	tempfile f
	save `f', replace
restore
merge m:1 naics4 using `f', nogen

*1.4: create FE
egen Inaics4 = group(naics4)
egen Isector = group(sector)

*1.5: outcome variable: log of labor productivity
gen ln_lp = ln(lp_lvl)

*******
**(2)**
*******

*2.1: baseline specification, weighting by pre-pandemic employment level
reghdfe ln_lp bartik_z* [aw=emp_lvlb], absorb(i.Inaics4 i.Isector i.year) vce(cluster Inaics4 year)

*2.2: create event study plot
tempfile f
parmest, saving(`f', replace)
preserve
	use `f', clear
	
	gen year = 2011 + _n -1
	format year %ty

	keep if strpos(parm,"bartik")
twoway (rarea min95 max95 year, fcolor(Blueish-gray8*0.15) lcolor(purple*0.15) lw(none) lpattern(solid)) ///
       (connected estimate year) ///
       (scatter estimate year, lwidth(thick) mcolor(black) msize(medsmall)), ///
       xtitle("") ytitle("Log Value") graphregion(color(white)) ///
       yline(0, lcolor(black) lwidth(thin)) xline(2020, lcolor(red)) legend(off) ///
       ylabel(, format(%9.2f))

	graph export "$figures/figure7.eps", replace
restore

       
