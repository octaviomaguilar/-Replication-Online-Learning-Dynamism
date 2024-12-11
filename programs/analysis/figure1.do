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
*plotting figure 1: The online learning rate overtime
use "$atus/atus_industry_educ_year.dta", clear

preserve
	collapse (mean) mean_educ_rate=online_educ_rate, by(year)
	replace mean_educ_rate = mean_educ_rate*100
	twoway (line mean_educ_rate year, lcolor(black) lwidth(medium)), /// line plot
		xtitle("Year", size(medium)) ///
		ytitle("Online Learning Rate (%)", size(medium)) ///
		legend(off) ///
		xlabel(2003(5)2023) ///
		ylabel(, )
	
	graph export "$figures/figure1.eps", replace

restore

