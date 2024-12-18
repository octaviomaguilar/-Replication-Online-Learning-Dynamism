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
/*
*1: Load BDS data
import delimited using "$data/bds/bds2021_vcn4_fac.csv", clear

*1.1: Drop obs with faulty data
drop if firms == "D" | firms =="X"
destring firms, replace

tostring vcnaics4, gen(naics4)

*1.2: generate firm age zero (startups)
gen firm_age_zero=0
replace firm_age_zero=1 if fage=="a) 0"

*1.3.1: calculate the number of firms aged zero (startups) by year-naics4
egen nfirms_age0 = sum(firms) if firm_age_zero==1, by(year naics4)

*1.3.2: calculate the total number of firms by year-naics4
egen nfirms = sum(firms), by(year naics4)

*1.4: restrict the sample to only firms age zero (startups)
keep if firm_age_zero==1

*1.5: generate the startup entry rate = (number of firms age zero/total number of firms)
gen entryrate = nfirms_age0/nfirms

*1.6: calculate the average entry rate by year-naics4
collapse (mean) entryrate, by (year naics4)

*1.7: set sample restriction for pre-trend period. Feel free to change this. Results are robust to different periods. 
drop if year < 2013

*1.8: merge in bartik measure at the 4-digit naics level
merge m:1 naics4 using "$data/bartik/bartik_naics4.dta", keep(3) nogen

*********
***(2)***
*********
*2.1: Create variables for event study:
sort naics4 year
gen t = year

*2.1.1: define the start and end period, and calculate the number of periods.
local begin = 2013
local end = 2021
local num = `end'-`begin'+1

local base = 2019

*2.1.2: loop through each period to generate binary (dummy) variables
forval i = 1/`num' {
	gen z`i' = t-`begin'+1 == `i'
}
*2.1.3: identify the offset of the base period relative to the start period and reset its dummy variable to 0.
local f = `base' - `begin' + 1
replace z`f' = 0

*2.1.4: filter dataset to include only rows at or after the start period.
keep if t >= `begin'

*2.1.5: loop to create interaction terms between `bartik` and each dummy variable.
forval i = 1/`num' {
	gen bartik_z`i' = bartik*z`i'
}
*2.1.6: generate a post-period indicator
gen post = t >= `base'

*2.2: create fixed effect groupings: 
egen Inaics4 = group(naics4)
gen naics2 = substr(naics4,1,2)
gen sec = naics2
replace sec = "31-33" if inlist(sec,"31","32","33")
replace sec = "44-45" if inlist(sec,"44","45")
replace sec = "48-49" if inlist(sec,"48","49")
egen Isec_t = group(sec t)

save "$data/bds/bds2021_vcn4_fac_trimmed.dta", replace 
*/
*********
***(3)***
*********
use "$data/bds/bds2021_vcn4_fac_trimmed.dta", clear

*3.1: run event study of bartik on startup entry rate, and plot the point estimates.
reghdfe entryrate bartik_z*, absorb(i.Isec_t i.Inaics4) vce(cluster t Inaics4)

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
       xtitle("") ytitle("Entry Rate") graphregion(color(white)) ///
       yline(0, lcolor(black) lwidth(thin)) xline(2019, lcolor(red)) legend(off) ///
       ylabel(, format(%9.2f))
       
       graph export "$figures/figure3_panelA.eps", replace

restore
