cap cls
clear all
set more off

global home "/mq/home/scratch/m1oma00/oma_projects/replication_online_productivity_oma_final"
global data "$home/data"
global cps "$home/data/cps"
global oes "$home/data/oes"
global ces "$data/ces"
global bds "$data/bds"
global bls "$data/bls"
global crosswalks "$data/crosswalks"

*******
**(1)**
*******
*1.1: Prepare BLS Industry Productivity data:
use "$bls/bls_ip_05july2024.dta", clear

keep if length(naics) == 4
rename naics naics4
drop if substr(naics4,1,1) == "1"
drop if substr(naics4,1,1) == "9"

gen naics_alt = substr(naics4,1,3)
replace naics_alt = naics_alt + "0"

*1.2: Merge in bartik measure at the 4-digit naics level
merge m:1 naics4 using "$data/bartik/bartik_naics4.dta"
drop if _m == 2
drop _m

rename naics4 temp
rename naics_alt naics4

merge m:1 naics4 using "$data/bartik/bartik_naics4.dta", update
drop if _m == 2
drop _m
drop naics4
rename temp naics4

sort naics4 year

save "$bls/blsip_naics4_regdata.dta", replace
