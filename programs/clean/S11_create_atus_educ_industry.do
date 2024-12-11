cap cls
clear all
set more off

global home = "/mq/scratch/m1oma00/oma_projects/replication_online_productivity_oma_final"
global data "$home/data"
global cps "$home/data/cps"
global oes "$home/data/oes"
global ces "$data/ces"
global figures "$home/figures"
global atus "$data/atus"
global crosswalks "$data/crosswalks"
global bed "$data/bed"

*******
**(1)**
*******
/* create ATUS dataset */
*1.1: load ATUS data:
use "$atus/atus_00011.dta", clear

*1.2: drop bad data quality
keep if dataqual == 200

*1.3: Restrict to employees aged 20-64
keep if age >= 25 & age <= 64
keep if empstat == 1 

*1.4: merge in PCE data
merge m:1 year using "$atus/pce_index_2019.dta", nogen // Took 2012 pcepi from FRED and changed to 2019 dollars 
gen incwage2019 = earnweek/pcepi_nbd20190101

keep if incwage2019 > (20000/52) & earnweek != 9999

keep if inlist(activity,060101, 060102)

*1.5: create a year month variable
gen ym = ym(year,month)
format ym %tm

*1.6: create quarterly variable
* Calculate the quarter based on month
gen quarter = ceil(month / 3)

*1.6.1: Create the quarterly date variable
gen qtr = yq(year, quarter)
format qtr %tq

*1.7: creating NAICS variable 
tostring ind_cps8, gen(naics)
drop if naics ==  "99999"

*1.8: merge in ATUS census industry coding to NAICS
merge m:1 naics using "$crosswalks/atus_to_supersec.dta", keep(3) nogen
replace naics2 = substr(naics2,1,2)
*dropping industries with insufficient obs
drop if inlist(naics2, "11", "21", "55")

*1.9: merge in naics2 to BED industry crosswalk
merge m:1 naics2 using "$crosswalks/naics2_to_bed_industry.dta", keep(3) nogen
*not matched is naics 92

*1.10: sum the duration of online learning across all respondents. 
preserve
	collapse (sum) duration, by(cpsidp year industry)

	keep cpsidp year industry
	gen education = 1
	
	tempfile education
	save "`education'"
restore 

*1.11: merge the duration of online learning across all respondents. 
merge m:1 cpsidp year industry using `education', nogen

*1.12: take the sum of time spent working for each individual
collapse (sum) duration (first) education wt06 wt20, by(cpsidp industry year where)

*1.13: drop duration less than 1 hour
drop if duration < 60

*1.14: define online learning to be at home or someone else's home
gen online_educ_atus = 0 
replace online_educ_atus = 1 if inlist(where, 101, 103, 109)

replace wt06 = round(wt06)
replace wt20 = round(wt20)

*1.15: calculate minutes spent learning and online learning by industry year
preserve 
	keep if year == 2020 
	collapse (sum) education online_educ_atus [fw=wt20], by(year industry)
	tempfile 2020
	save `2020', replace
restore
	
collapse (sum) education online_educ_atus [fw=wt06], by(year industry)
append using `2020'

*1.16: calculate the online learning rate, defined to be: (online learning time/total time spent learning) by super-sector year. 
gen online_educ_rate = online_educ_atus/ education
sort year industry
keep year industry online_educ_rate

save "$atus/atus_industry_educ_year.dta", replace

