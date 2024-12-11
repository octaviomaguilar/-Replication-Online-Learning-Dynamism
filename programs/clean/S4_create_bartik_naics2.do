cap cls
clear all
set more off

global home "/mq/home/scratch/m1oma00/oma_projects/replication_online_productivity_oma_final"
global data "$home/data"
global cps "$home/data/cps"
global oes "$home/data/oes"
global ces "$data/ces"
global crosswalks "$data/crosswalks"

*******
**(1)**
*******
*1.1: Get oes distribution at naics2 level
import excel "$oes/natsector_M2019_dl.xlsx", sheet("Natsector_M2019_dl") firstrow

*1.2: Get total employment for each industry
keep if o_group == "total"
keep naics tot_emp
destring tot_emp, replace

*1.2.1: save as temp file
tempfile f
save `f', replace

*******
**(2)**
*******
*2.1: Get total employment by naics2 and occupation
import excel "$oes/natsector_M2019_dl.xlsx", sheet("Natsector_M2019_dl") firstrow clear
keep if o_group == "minor"
gen occ2 = substr(occ_code,1,3)
replace occ2 = subinstr(occ2,"-","",.)
keep naics occ2 tot_emp

replace tot_emp = "" if tot_emp == "**"
destring tot_emp, gen(emp)
drop tot_emp

*2.2: merge with block 1:
merge m:1 naics using `f', nogen

*******
**(3)**
*******
*3.1: generating theta_{i,o}
gen theta_io = emp/tot_emp

*3.2: merging CPS 2019-2021 delta education data 
merge m:1 occ2 using "$cps/cps_delta_educ.dta", keep(3) nogen

*3.3: creating bartik shock: taking the product of the shift (cps education) and the share (theta_{i,o})
gen prod = theta_io*delta_educ
collapse (sum) bartik=prod, by(naics)

save "$data/bartik/bartik_naics2.dta", replace
