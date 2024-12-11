cap cls
clear all
set more off
*ssc install mdesc
*ssc install reghdfe
*ssc install ftools
*ssc install parmest

global home = "/mq/scratch/m1oma00/oma_projects/replication_online_productivity_oma_final"
global data "$home/data"
global cps "$home/data/cps"
global oes "$home/data/oes"
global ces "$data/ces"
global bds "$data/bds"
global figures "$home/figures"
global crosswalks "$data/crosswalks"
global bed "$data/bed"
global atus "$data/atus"

*********
***(1)***
*********
*Table 1:
use "$cps/cps_delta_educ.dta", clear

format %9.3f online_educ2019 online_educ2021 delta_educ 
list, noobs abbreviate(12) sepby(occ2)

********************************************************************************************************************************************************************************
********************************************************************************************************************************************************************************
********************************************************************************************************************************************************************************
********************************************************************************************************************************************************************************
********************************************************************************************************************************************************************************
*Table 2: output is given in line 205. 

*********
***(2)***
*********
/* Produce table 2 column 1: BED entry-rates pre and post-pandemic.*/ 
use "$atus/atus_industry_educ_year.dta", clear
destring industry, gen(panel_variable)

*merge in BED super sector data: 
merge 1:1 year industry using "$bed/bed_industry_year.dta", keep(3) nogen

*exclude natural resources and mining and financial activities
*drop if industry == "10001" | industry == "20006"

*setting it to be panel data:
xtset panel_variable year

*transformation variables into log form
gen log_entry = ln(birth_lvl)
gen log_exit = ln(death_lvl)

*create FEs
egen isector = group(industry)
egen itime = group(year)

*Estimate column 1 Panel A and Panel B from table 2:
*regression using lags of the DV:

*pre-pandemic sample, Column 1 Panel A 
qui reghdfe log_entry online_educ_rate L(1/2).log_entry if year >= 2003 & year <=2019, absorb(isector itime) 
estadd local secFE Y
estadd local yearFE Y
estadd local lags Y
estimates store m1, title("(1)")

*full sample, Column 1 Panel B
qui reghdfe log_entry online_educ_rate L(1/2).log_entry if year >= 2003 & year <= 2022, absorb(isector itime)
estadd local secFE Y
estadd local yearFE Y
estadd local lags Y
estimates store m2, title("(2)")

********************************************************************************************************************************************************************************
********************************************************************************************************************************************************************************
********************************************************************************************************************************************************************************
********************************************************************************************************************************************************************************
********************************************************************************************************************************************************************************
/* Produce table 2 columns 2-4: BDS entry-rates pre and post-pandemic.*/ 

***********
***(2.1)***
***********
import delimited using "$bds/bds2021_sec_fac.csv", clear

/* Cleaning */
drop if year < 2003
gen naics2 = substr(sector,1,2)

foreach x in estabs_entry estabs emp {
drop if `x' == "D" | `x' =="X" | `x' == "N"
destring `x', replace
}

*clean firm age coarse 
gen fage0=0
replace fage0=1 if fagecoarse=="a) 0"

gen fage1=0
replace fage1=1 if fagecoarse=="b) 1 to 5"

gen fage2=0
replace fage2=1 if fagecoarse=="c) 6 to 10"

gen fage3=0
replace fage3=1 if fagecoarse=="d) 11+"

gen fage4=0
replace fage4=1 if fagecoarse=="e) Left Censored"

*create new firm age groups
gen fageg = 0 
replace fageg = 1 if fage0 == 1 
replace fageg = 2 if fage1 == 1
replace fageg = 3 if fage2 == 1 
replace fageg = 4 if fage3 == 1 
replace fageg = 5 if fage4 == 1

keep year naics2 estabs estabs_entry emp fageg

*merge in naics to BED industry xwalk
merge m:1 naics2 using "$crosswalks/naics2_to_bed_industry.dta", keep(3) nogen

collapse (mean) estabs_entry [aw=estabs], by(year industry fageg)

gen new = fageg == 1
gen young = fageg == 1 | fageg == 2

***********
***(2.2)***
***********
*merge in ATUS wfh rate data
merge m:1 year industry using "$atus/atus_industry_educ_year.dta", keep(3) nogen
*not matched is year 2022 since BDS does not have 2022 vintage yet.

*exclude natural resources and mining and financial activities
*drop if industry == "10001" | industry == "20006"

*setting it to be panel data:
*destring industry, gen(panel_varaible)
egen panel_variable = group(industry fageg)
xtset panel_variable year

*transformation variables into log form
gen log_entry = ln(estabs_entry)

*create FEs
egen isector = group(industry)
egen itime = group(year)

save "$bds/bds2021_sec_fac_trimmed.dta", replace

***********
***(2.3)***
***********
use "$bds/bds2021_sec_fac_trimmed.dta", clear
*pre-pandemic sample: all obs; Table 2 column 2 Panel A
qui reghdfe log_entry online_educ_rate L(1/2).log_entry if year >= 2003 & year <= 2019, absorb(isector itime) 
estadd local secFE Y
estadd local yearFE Y
estadd local lags Y
estimates store m3, title("(3)")

*full sample: all obs; Table 2 column 2 Panel B
qui reghdfe log_entry online_educ_rate L(1/2).log_entry if year >= 2003 & year <= 2021 , absorb(isector itime)
estadd local secFE Y
estadd local yearFE Y
estadd local lags Y
estimates store m4, title("(4)")

***********
***(2.4)***
***********
*pre-pandemic sample: new firms; Table 2 column 3 Panel A
qui reghdfe log_entry online_educ_rate  L(1/2).log_entry if year >= 2003 & year <=2019 & new == 1, absorb(isector itime) 
estadd local secFE Y
estadd local yearFE Y
estadd local lags Y
estimates store m5, title("(5)")

*full sample: new firms; Table 2 column 3 Panel B
qui reghdfe log_entry online_educ_rate  L(1/2).log_entry if new == 1, absorb(isector itime)
estadd local secFE Y
estadd local yearFE Y
estadd local lags Y
estimates store m6, title("(6)")

***********
***(2.5)***
***********
*pre-pandemic sample: young firms; Table 2 column 4 Panel A
qui reghdfe log_entry online_educ_rate  L(1/2).log_entry if year >= 2003 & year <=2019  & young == 1, absorb(isector itime) 
estadd local secFE Y
estadd local yearFE Y
estadd local lags Y
estimates store m7, title("(7)")

*full sample: young firms; Table 2 column 4 Panel B
qui reghdfe log_entry online_educ_rate  L(1/2).log_entry  if young == 1, absorb(isector itime)
estadd local secFE Y
estadd local yearFE Y
estadd local lags Y
estimates store m8, title("(8)")

*Regression output: Table 2:
estout m1 m2 m3 m4 m5 m6 m7 m8, cells(b(fmt(%9.4f)) se(par fmt(%9.4f))) keep(online_educ_rate) stats(r2 N secFE yearFE lags, fmt(%9.2f %9.0fc ) label(R-sqr N "SectorFE" "YearFE" "Lags")) legend label

