/*******************************************************************************
********************************************************************************
Author: Elena Raffetti
Date: Nov 2021

List of databases used to study contextual factors and prevalence of vaccination with at least one dose


name: EUROPE_COVID19_master
type: Stata
download from https://www.nature.com/articles/s41597-021-00950-7?proof=tNature

name:italy_nuts.dta
type: Stata
data from https://eurlex.europa.eu/legal-content/EN/TXT/?uri=celex%3A32017R2391
(available in data)

name: exc_mortality_sweden
Type: excel
data from https://github.com/eleraf/epidemics-risk-perception/blob/main/excess_mortality.do
(available in data)


name: exc_mortality_italy
Type: excel
data from https://academic.oup.com/ije/article/49/6/1909/5923437
(available in data)


name: vaccianated_one_dose_italy_v31_33
Type: excel
data from: https://www.gimbe.org/pagine/341/it/comunicati-stampa
(available in data)


name: vaccianated_one_dose_sweden_v32
Type: excel
data from: https://www.folkhalsomyndigheten.se/the-public-health-agency-of-sweden/communicable-disease-control/COVID-19/statistics/
(available in data)

********************************************************************************
*******************************************************************************/
** define cumulative incidence
clear all
use EUROPE_COVID19_master.dta

keep if country=="Italy" | country=="Sweden"
keep if date == td(15aug2021)

rename nuts3_id NUTS3_code

*redefine NUTS3_code
replace NUTS3_code = subinstr(NUTS3_code, "ITI", "ITE", .) 
replace NUTS3_code = subinstr(NUTS3_code, "ITH", "ITD", .) 

replace NUTS3_code = "ITF41" if NUTS3_code == "ITF43"
replace NUTS3_code = "ITF42" if NUTS3_code == "ITF44"
replace NUTS3_code = "ITF43" if NUTS3_code == "ITF45"
replace NUTS3_code = "ITF44" if NUTS3_code == "ITF46"
replace NUTS3_code = "ITF45" if NUTS3_code == "ITF47" | NUTS3_code == "ITF48"

replace  NUTS3_code = "ITC4A"   if  NUTS3_code == "ITC4C"   |  NUTS3_code =="ITC4D"

replace  NUTS3_code = "ITE34"   if  NUTS3_code == "ITE35"  

merge m:1 NUTS3_code using italy_nuts, keepusing(NUTS2_name)

drop if _merge==2
drop _merge

replace NUTS2_name = "Stockholm" if nuts_name=="Stockholms län"
replace NUTS2_name = "Ostramellansverige"  if nuts_name=="Västmanlands län" | nuts_name== "Örebro län" | nuts_name== "Södermanlands län" | nuts_name== "Östergötlands län" | nuts_name== "Uppsala län"
replace NUTS2_name = "Smaland" if nuts_name== "Gotlands län"  | nuts_name== "Kalmar län" | nuts_name=="Kronobergs län" | nuts_name== "Jönköpings län"
replace NUTS2_name = "Sydsverige" if nuts_name== "Skåne län" | nuts_name== "Blekinge län" 
replace NUTS2_name = "Vastsverige" if nuts_name==  "Västra Götalands län" | nuts_name== "Hallands län"
replace NUTS2_name = "Norramellansverige"  if nuts_name==  "Värmlands län" | nuts_name== "Dalarnas län" | nuts_name== "Gävleborgs län"
replace NUTS2_name = "Mellerstanorrland" if nuts_name==  "Jämtlands län" | nuts_name== "Västernorrlands län" 
replace NUTS2_name = "Ovrenorrland" if nuts_name==  "Västerbottens län" | nuts_name== "Norrbottens län" 

replace NUTS2_name = "Trentino-Alto Adige" if nuts_id=="ITH10" | nuts_id=="ITH20"

collapse (sum)  population (sum) cases, by(NUTS2_name)

gen cum_inc = cases/population*1000

rename NUTS2_name region

save cum_inc.dta, replace
********************************************************************************
**upload excess mortality

clear
import excel "C:\Users\elera574\Documents\UU\uppsalasurvey\exc_mortality_italy", firstrow
keep ExcessPer region
tempfile italyexc
replace region = "Puglia" if region=="Apulia"
replace region = "Sicilia" if region=="Sicily"
save `italyexc'

clear
import excel "C:\Users\elera574\Documents\UU\uppsalasurvey\exc_mortality_sweden", firstrow
gen region = "Stockholm" if NUTS2==1
replace region  = "Ostramellansverige"  if NUTS2==2
replace region  = "Smaland" if NUTS2==3
replace region  = "Sydsverige" if NUTS2==4
replace region  = "Vastsverige" if NUTS2==5
replace region  = "Norramellansverige"  if NUTS2==6
replace region  = "Mellerstanorrland" if NUTS2==7
replace region  = "Ovrenorrland" if NUTS2==8
drop if ExcessPer==.
keep ExcessPer region
append using `italyexc'
tempfile mortalityexc
save `mortalityexc'

********************************************************************************
** define COVID-19 vaccination coverage
clear
import excel vaccianated_one_dose_italy_v31_33, firstrow
rename regione region
gen prev_vaccination = ((full_v31+ first_v31) + (full_v33+ first_v33))/2
keep region prev_vaccination

gen k = 0 if region == "Trento"
replace k = 1 if region == "Bolzano"
sort k

gen j =.
replace j =  prev_vaccination[_n-1]  if k!=.
replace prev_vaccination = (prev_vaccination+j)/2 if region == "Bolzano"
drop if  region == "Trento"
replace region = "Trentino-Alto Adige" if region== "Bolzano"
gen country="Italy"
drop k j 
tempfile italyvaccination
save `italyvaccination'


clear 
import excel vaccianated_one_dose_sweden_v32, firstrow

gen region = "Stockholm" if nuts_name=="Stockholm"
replace region  = "Ostramellansverige"  if nuts_name=="Västmanland" | nuts_name== "Örebro" | nuts_name== "Södermanland" | nuts_name== "Östergötland" | nuts_name== "Uppsala"
replace region  = "Smaland" if nuts_name== "Gotland"  | nuts_name== "Kalmar" | nuts_name=="Kronoberg" | nuts_name== "Jönköping"
replace region  = "Sydsverige" if nuts_name== "Skåne" | nuts_name== "Blekinge" 
replace region  = "Vastsverige" if nuts_name==  "Västra Götaland" | nuts_name== "Halland"
replace region  = "Norramellansverige"  if nuts_name==  "Värmland" | nuts_name== "Dalarna" | nuts_name== "Gävleborg"
replace region  = "Mellerstanorrland" if nuts_name==  "Jämtland" | nuts_name== "Västernorrland" 
replace region  = "Ovrenorrland" if nuts_name==  "Västerbotten" | nuts_name== "Norrbotten" 

collapse (sum) total_vaccinated, by(region)
gen country="Sweden"
append using `italyvaccination'

merge 1:1 region using cum_inc.dta
drop _merge

merge 1:1 region using `mortalityexc'
drop _merge

replace prev_vaccination = total_vaccinated/population*100 if prev_vaccination==.


regress prev_vaccination cum_inc if country=="Sweden"
regress prev_vaccination cum_inc if country=="Italy"

regress prev_vaccination ExcessPer if country=="Sweden"
regress prev_vaccination ExcessPer if country=="Italy"


keep prev_vaccination region country cum_inc
order country

*excel file to prepare maps
export excel using "vaccination_map", replace firstrow(variables)
