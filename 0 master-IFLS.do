* ******************************************************************************
* PROJECT: IFLS
* AUTHORS: LOLITA MOORENA
* PURPOSE: Master do-file 
* ******************************************************************************

* A) PRELIMINARIES
set more off
clear all
cap log close

* B) WORKING FOLDER PATH

** Macbook computer
if "`c(username)'"=="lolitamoorena" {
	version 16
	gl path "/Users/lolitamoorena"
	gl code "$path/Documents/Github/mt-merapi"	
	gl raw "$path/Library/CloudStorage/OneDrive-AustralianNationalUniversity/ADBI - Elghafiky Bimardhika's files/2 Data"
	gl outpath "$path/Library/CloudStorage/OneDrive-AustralianNationalUniversity/ADBI - Elghafiky Bimardhika's files/2 Data"
	}

* Fiky's laptop
if "`c(username)'"=="elgha" {
	version 16
	gl path "C:\Users\elgha"
	gl code "$path\OneDrive/Documents/Github/mt-merapi"	
	gl raw "$path\OneDrive - Australian National University\Work\ADBI/2 Data"
	gl outpath "$path\OneDrive - Australian National University\Work\ADBI/2 Data"
	gl log "$path\OneDrive - Australian National University\Work\ADBI/2 Data/1 IFLS/4 Log"
	}
	
* Campus PC
if "`c(username)'"=="u7083951" {
	version 18
	gl path "C:\Users\u7083951"
	gl code "\\homedrive.anu.edu.au\users\u7083951\My Documents\GitHub\mt-merapi"	
	gl raw "$path\OneDrive - Australian National University\Work\ADBI/2 Data"
	gl outpath "$path\OneDrive - Australian National University\Work\ADBI/2 Data"
	gl log "$path\OneDrive - Australian National University\Work\ADBI/2 Data/1 IFLS/4 Log"
	}
	
*** The following paths will update automatically ***

gl ifls  	"$raw/1 IFLS/2 Raw Data"
gl ifls4 	"$raw/1 IFLS/2 Raw Data/IFLS 4"
gl ifls5 	"$raw/1 IFLS/2 Raw Data/IFLS 5"
gl vol 		"$raw/6 Smithsonian Institution"
gl pod		"$raw/2 PODES"

gl input "$outpath/1 IFLS/3 Processed data/data/raw data/IFLS"
gl temp "$outpath/1 IFLS/3 Processed data/data/temp/IFLS"
gl final "$outpath/1 IFLS/3 Processed data/data/final/IFLS"

gl tables "$outpath/1 IFLS/3 Processed data/TABLES/IFLS"
gl figures "$outpath/1 IFLS/3 Processed data/figures/IFLS"

********************************************************************************
** STEP 1: Data Preparation 
********************************************************************************

** IFLS household codes
do "$code/build/code-1-data-preparation.do"
do "$code/build/code-2-get-data.do"
do "$code/build/code-3-rename-recode-data.do"
do "$code/build/code-4-label-data.do"
do "$code/build/code-5-sample-construction.do"
do "$code/build/code-6-data-construction.do"

** IFLS community codes
do "$code/build/code-1-get-data-community.do"

** PODES codes
do "$code/build/code-1-podes-data-preparation.do"

********************************************************************************
** STEP 2: Summary Statistics of Tables and Figures
********************************************************************************

*** Descriptive Stats ***
do "$code/analysis/code-summstat.do"
do "$code/analysis/code-indovolcanoes.do"

*** Analysis ***  
do "$code/analysis/code-psm-common-did-mount.do"  
do "$code/analysis/code-psm-caliper-did-mount.do"  
do "$code/analysis/code-psm-did-stacked.do"  
do "$code/analysis/code-cem-entropy-did.do"  
do "$code/analysis/code-multi-did.do" 
do "$code/analysis/code-alternative specifications.do"  
do "$code/analysis/code-mechanism.do"  
