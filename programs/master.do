cap cls
clear all
set more off

global home = "/mq/scratch/m1oma00/oma_projects/replication_online_productivity_oma_final"
global data "$home/data"
global cps "$home/data/cps"
global oes "$home/data/oes"
global ces "$data/ces"
global bds "$data/bds"
global bls "$data/bls"
global figures "$home/figures"
global crosswalks "$data/crosswalks"
global qwi "$data/qwi"
global programs "$home/programs"

*To run this master file from start to finish you must have ALL the raw data as listed in the README. 
*If you do not, this master will only run block 2, the analysis. 
*******
**(1)**
*******
*running all programs to import, create variables and datasets and clean the data:

do "$programs/clean/S1_create_delta_learning.do"

do "$programs/clean/S2_create_bartik_naics3.do"

do "$programs/clean/S3_create_bartik_naics4.do"

do "$programs/clean/S4_create_bartik_naics2.do"

do "$programs/clean/S5_create_blsip_naics4_regdata.do"

do "$programs/clean/S6_create_bartik_state_naics4_emp_fsize.do"

do "$programs/clean/S7_create_bartik_state_naics4_emp_fage.do"

do "$programs/clean/S8_import_qcew.do"

do "$programs/clean/S9_create_qcew_sector_naics3.do"

do "$programs/clean/S10_create_bed_industry.do"

do "$programs/clean/S11_create_atus_educ_industry.do"

do "$programs/clean/S12_create_bed_atus_educ.do"

do "$programs/clean/S13_create_qwi_bartik_earn_fage.do"

do "$programs/clean/S14_create_qwi_bartik_earn_fsize.do"

*******
**(2)**
*******
*running all the programs for analysis: figures and tables in the paper.

/* Figures */
do "$programs/analysis/figure1.do"

do "$programs/analysis/figure2.do"

do "$programs/analysis/figure3_panelA.do"

do "$programs/analysis/figure3_panelB.do"

do "$programs/analysis/figure4_panelC.do"

do "$programs/analysis/figure4_panelD.do"

do "$programs/analysis/figures_dev_empshare_fage.do"

do "$programs/analysis/figures_dev_empshare_fsize.do"

do "$programs/analysis/figure6_panelA_to_panelD.do"

do "$programs/analysis/figure6_panelE_to_panelG.do"

do "$programs/analysis/figure7.do"

/* Tables */
do "$programs/analysis/tables.do"




