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

*********
***(1)***
*********
*import and save QCEW files:
/*
forval i = 2005/2016 {
	import delimited "$qcew/`i'.q1-q4.singlefile.csv", clear
	save "$qcew/qcew`i'.dta", replace
}

import delimited "$qcew/2023.q1-q4.singlefile.csv", clear
save "$qcew/qcew2023.dta", replace
*/
