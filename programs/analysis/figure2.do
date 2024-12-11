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
*load BED-ATUS online learning rate data
use "$bed/bed_atus_educ.dta", clear

*1.1 define periods 
gen pre_pandemic = 1 if time_temp >= 232 & time_temp <=239
gen full_sample = 1 if time_temp >= 232 & time_temp <=251
gen start_sample = 1 if time_temp >= 172 & time_temp <=179

foreach x in pre_pandemic full_sample start_sample {
	replace `x' = 0 if `x' ==. 
}

*1.2 calculate average online learning for each defined period: 
preserve
	collapse (mean) pre_pandemic_educ = online_educ_rate if pre_pandemic == 1, by(industry)
	tempfile pre_pandemic_educ
	save `pre_pandemic_educ', replace
restore 

preserve
	collapse (mean) full_sample_educ = online_educ_rate if full_sample == 1, by(industry)
	tempfile full_sample_educ
	save `full_sample_educ', replace
restore 

preserve
	collapse (mean) start_sample_educ = online_educ_rate if start_sample == 1, by(industry)
	tempfile start_sample_educ
	save `start_sample_educ', replace
restore 

*1.3 calculate average entry and exit for each defined period
*birth
preserve
	collapse (mean) pre_pandemic_birth = birth_rate if pre_pandemic == 1, by(industry)
	tempfile pre_pandemic_birth
	save `pre_pandemic_birth', replace
restore 

preserve
	collapse (mean) full_sample_birth = birth_rate if full_sample == 1, by(industry)
	tempfile full_sample_birth
	save `full_sample_birth', replace
restore 

collapse (mean) start_sample_birth = birth_rate if start_sample == 1, by(industry)
tempfile start_sample_birth
save `start_sample_birth', replace

*1.4 merge data needed for figure 2:

merge 1:1 industry using `pre_pandemic_educ', keep(3) nogen
merge 1:1 industry using `full_sample_educ', keep(3) nogen
merge 1:1 industry using `start_sample_educ', keep(3) nogen

merge 1:1 industry using `pre_pandemic_birth', keep(3) nogen
merge 1:1 industry using `full_sample_birth', keep(3) nogen

*1.5 Calculate percentage point changes for education rates
by industry: gen change_educ_pre = (pre_pandemic_educ - start_sample_educ)*100
by industry: gen change_educ_full = (full_sample_educ - start_sample_educ)*100

*1.6 Calculate percentage changes for entrants (birth_rate)
gen change_birth_pre = 100 * (pre_pandemic_birth - start_sample_birth) / start_sample_birth
gen change_birth_full = 100 * (full_sample_birth - start_sample_birth) / start_sample_birth

order industry pre_pandemic_educ full_sample_educ start_sample_educ change_educ_pre change_educ_full pre_pandemic_birth full_sample_birth start_sample_birth change_birth_pre change_birth_full 

*******
**(2)**
*******
* Plotting figure entry: 
twoway (scatter change_birth_pre change_educ_pre, mcolor(gray) msymbol(circle)) ///
       (scatter change_birth_full change_educ_full, mcolor(blue) msymbol(circle)) ///
       (lfit change_birth_pre change_educ_pre, lcolor(gray) lpatter(dash)) ///
       (lfit change_birth_full change_educ_full, lcolor(blue)), ///
        xtitle("Online Learning Rate Changes (p.p.)") ytitle("Entry Changes (%)") ///
	legend(order(1 "pre-pandemic" 2 "full sample"))
	graph export "$figures/figure2.eps", replace
