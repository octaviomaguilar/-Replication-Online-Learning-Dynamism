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
global qcew "$start/data/qcew"

/*
*********
***(1)***
*********
*create sector employment for each year from 2003-2023
forval yr = 2003/2023 {
	use "$qcew/qcew`yr'.dta", clear

	keep if agglvl_code == 14 /* NAICS Sector -- by ownership sector */
	keep if own_code == 5	/* Private */

	gen naics2 = substr(industry_code,1,2)

	*merge in naics2 to BED industry crosswalk
	merge m:1 naics2 using "$replication/crosswalks/naics2_to_bed_industry.dta", keep(3) nogen
	*not matched is naics 99

	*average employment per quarter
	egen emp_sector = rowmean(month1_emplvl month2_emplvl month3_emplvl)	
	replace emp_sector = . if inlist(disclosure_code, "-", "N")

	*average employment per year by BED industry
	collapse (mean) emp_sector, by(year industry)

	save "$qcew/qcew_sector_emp`yr'.dta", replace
}

***********
***(1.1)***
***********
*append all employment data into 1 dataset
use "$qcew/qcew_sector_emp2003.dta", clear
forval yr = 2004/2023 {
    append using "$qcew/qcew_sector_emp`yr'.dta"
}
save "$qcew/qcew_sector_emp_all.dta", replace

*remove files from step 1.
forval yr = 2003/2023 {
    rm "$qcew/qcew_sector_emp`yr'.dta"
}

*********
***(2)***
*********
*create naics3 employment for each year from 2003-2023
forval yr = 2003/2023 {
	use "$qcew/qcew`yr'.dta", clear

	keep if agglvl_code == 15 /* NAICS 3-digit -- by ownership sector */
	keep if own_code == 5	/* Private */

	*average employment per quarter
	egen emp_naics3 = rowmean(month1_emplvl month2_emplvl month3_emplvl)	
	replace emp_naics3 = . if inlist(disclosure_code, "-", "N")

	gen t = yq(year,qtr)
	format t %tq
	
	*average employment per year by industry
	collapse (mean) emp_naics3, by(t industry_code)
	gen naics3 = industry_code
	drop industry_code
	
	save "$qcew/qcew_naics3_emp`yr'.dta", replace
}

***********
***(2.1)***
***********
*append all employment data into 1 dataset
use "$qcew/qcew_naics3_emp2003.dta", clear
forval yr = 2004/2023 {
    append using "$qcew/qcew_naics3_emp`yr'.dta"
}
save "$qcew/qcew_naics3_emp_all.dta", replace

*remove files from step 1.
forval yr = 2003/2023 {
    rm "$qcew/qcew_naics3_emp`yr'.dta"
}

*/
