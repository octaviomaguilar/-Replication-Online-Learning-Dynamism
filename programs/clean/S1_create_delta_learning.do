cap cls
clear all
set more off

global home "/mq/home/scratch/m1oma00/oma_projects/replication_online_productivity_oma_final"
global data "$home/data"
global cps "$home/data/cps"
global crosswalks "$data/crosswalks"

*This code creates "delta learning_s": changes in online learning from 2019 to 2021 across two-digit occupations "s" using the CPS-CIS. 
*Block 1 creates weighted online learning shares in 2019
*Block 2 creates weighted online learning shares in 2021
*Block 3 merges data from block 1 and block 2 to have 1 file with 2019 and 2021 shares. It then calculates the change between the two years. 
*******
**(1)**
*******
*1. Create 2019 2-digit occupation online learning shares 
import delimited "$cps/nov19pub.csv", clear

*1.1: set sample restrictions:
drop if prdtocc1 == -1 | prdtocc1 == 23
drop if prdtocc1 == . 
keep if prtage >= 16 & prtage < 55
keep if prempnot == 1
drop if peedtrai == -1

gen employed =1 if prempnot==1
gen online_educ = peedtrai

*1.2: merge in occ cps to occ oes xwalk
tostring prdtocc1, gen(cps_occ)

merge m:1 cps_occ using "$crosswalks/occxwalk.dta"
drop _m 

gen occ2 = oes_occ
replace online_educ = 0 if online_educ == 2

*1.3: calculate weighted shares of online learning in 2019 by 2-digit occupation
collapse (mean) online_educ [aw=pwsswgt], by(occ2)
sort occ2

rename online_educ online_educ2019

*1.4: save as a temp file: 
tempfile educ2019
save `educ2019', replace

*******
**(2)**
*******
*2. Create 2021 2-digit occupation online learning shares 
import delimited "$cps/nov21pub.csv", clear

*2.1: set sample restrictions:
drop if prdtocc1 == -1 | prdtocc1 == 23
drop if prdtocc1 == . 
keep if prtage >= 16 & prtage < 55
keep if prempnot == 1
drop if peedtrai == -1

gen online_educ = peedtrai

*2.2: merge in occ cps to occ oes xwalk
tostring prdtocc1, gen(cps_occ)

merge m:1 cps_occ using "$crosswalks/occxwalk.dta"
drop _m 

gen occ2 = oes_occ
replace online_educ = 0 if online_educ == 2

*2.3: calculate weighted shares of online learning in 2021 by 2-digit occupation
collapse (mean) online_educ [aw=pwsswgt], by(occ2)
sort occ2
rename online_educ online_educ2021

*******
**(3)**
*******
*3. merge data from block 1 and block 2: 
merge 1:1 occ2 using `educ2019'
drop _m

*3.1: create changes in online learning between 2019 and 2021.
gen delta_educ = online_educ2021-online_educ2019
keep occ2 delta online_educ2021 online_educ2019

*3.2: save as clean dataset:
save "$cps/cps_delta_educ.dta", replace
