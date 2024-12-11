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
global qwi "$data/qwi"
global crosswalks "$data/crosswalks"

*********
***(1)***
*********
*1: updating the vintage for the 2017 naics codes to be 2022. 

*1.1: load vintage xwalk:
use "$crosswalks/2017naics4_to_2022naics4.dta", clear

*1.2: merge in bartik measure at the 4-digit industry level.
merge m:1 naics4 using "$data/bartik/bartik_naics4.dta", nogen 
*1.2.1: update vintage
replace naics4 = oes_2022naics4 if oes_2017naics4 != .

duplicates tag naics4, gen(dup)
drop if dup > 0
drop dup

keep naics4 bartik

*1.3: save as a temp dataset
save "$data/bartik_naics4_temp.dta", replace

*********
***(2)***
*********
*2: Prepare QWI data by firm size group:
use "$qwi/qwi_state_naics4_size.dta", clear

*firmsize 0: "All firm sizes"
*firm sizes 1-5: 0-19, 20-49, 50-249, 250-499, and 500+ employees

*2.1: Cleaning
tostring industry, gen(naics4)
drop if naics4 == "0"
drop industry

*dropping faulty geography
drop if geography == 72

*generating "time" to be YYQQ
gen time = yq(year,quarter)
format time %tq 
drop year quarter

rename geography statefips

drop if substr(naics4,1,1) == "1"
drop if substr(naics4,1,1) == "9"

*2.2: merging with the bartik temp file from step 1.3 above
merge m:1 naics4 using "$data/bartik_naics4_temp.dta", keep(3) nogen
sort naics4 state time

save "$data/bartik/bartik_state_naics4_fsize.dta", replace
rm "$data/bartik_naics4_temp.dta"
