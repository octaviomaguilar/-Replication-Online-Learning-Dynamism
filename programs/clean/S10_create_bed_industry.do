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
global bed "$data/bed"

/* Mini codebook of variables:
unit of analysis = 1, which is establishments
data element = 1 is employment and = 2 is number of establishments
size class: 01-09 are number of employees
data class = 07 is establishment birth and data class = 08 is establishment deaths.
rate level: L = level, R = rate
Periodicity: A = annual and Q = quarterly
own code = 5 is private.
*/

*******
**(1)**
*******
*1.1: import raw BED data 
import delimited "$bed/bd.data.0.Current", clear

*1.2: generating key variables: 
gen state_fips = substr(series_id,9,2)
gen industry = substr(series_id,14,5)
gen unit_analysis = substr(series_id,20,1)
gen data_element = substr(series_id,21,1)
gen size_class = substr(series_id,22,2)
gen data_class = substr(series_id,24,2)
gen rate_level = substr(series_id,26,1)
gen periodicity_code = substr(series_id,27,1)
gen own_code = substr(series_id,28,1)
gen season = substr(series_id,3,1)

*1.3: *trimming the "value" variable since there are many spaces in the cell.
replace value = trim(value)
drop if value == "-"
destring value, replace

*1.4: create quarterly/year date variable
gen qtr = substr(period,3,1)
destring qtr, replace

gen t = yq(year,qtr)
format t %tq

*1.5: keep U.S. totals for state fips: 
keep if state_fips == "00"

*1.6: dropping total private industry codes.
drop if industry == "00000"

*1.7: keeping only seasonally adjusted variables 
keep if season == "S" 

*1.8: keep only information on establishment birth and exit
keep if inlist(data_class,"07","08")
keep if data_element == "2"

*1.9: drop aggregate industries 
drop if industry == "10000" | industry == "20000" 

*1.10: exclude natural resources and mining and financial activities
drop if industry == "10001" | industry == "20006"

*1.11: drop utilities since there is no information available
drop if industry == "20004"

*1.12: reshape the data: create temp for rates and levels. 
gen temp = .
replace temp = 1 if rate_level == "R"
replace temp = 2 if rate_level == "L"

keep t value industry temp data_class

*1.13: reshape by rates and levels
reshape wide value, i(industry data_class t) j(temp)

rename value1 rate
rename value2 level

*1.14: reshape by establishment birth or death
destring data_class, replace 
reshape wide rate level, i(industry t) j(data_class)

rename rate7 birth_rate
rename level7 birth_lvl
rename rate8 death_rate
rename level8 death_lvl

/*
*calculate birth rate by industry 
preserve
	collapse (mean) birth_rate, by(industry t)
	tempfile birth
	save `birth', replace
restore

*calculate birth level by super sector 
preserve
	collapse (mean) birth_lvl, by(industry t)
	tempfile birthlvl
	save `birthlvl', replace
restore

*calculate death level by super sector 
preserve
	collapse (mean) death_lvl, by(industry t)
	tempfile deathlvl
	save `deathlvl', replace
restore

*calculate exit rate by super sector 
collapse (mean) death_rate, by(industry t)

merge 1:1 t industry using `birth', keep(3) nogen
merge 1:1 t industry using `birthlvl', keep(3) nogen
merge 1:1 t industry using `deathlvl', keep(3) nogen
*/
save "$bed/bed_industry.dta", replace
