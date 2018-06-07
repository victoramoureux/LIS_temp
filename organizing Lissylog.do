clear
cd "C:\Users\101625\Desktop\lis_tax_transfer_VA"

/*ssc install missings*/
/*ssc install kountry*/
/*Juste cette fois*/

****************************************************************************************
*********Put together the country level variable from Inequality measures 1 to 6********
****************************************************************************************


import delimited "Export déciles.csv", delimiter(comma) varnames(1) clear

**drop the decile part****
drop if decile=="D01"|decile=="D02"|decile=="D03"|decile=="D04"|decile=="D05"|decile=="D06"|decile=="D07"|decile=="D08"|decile=="D09"|decile=="D10"

*******sort so that the headers becomes the first 6 obs****
gsort -inc1_mean_1


keep decile 
duplicates drop decile, force 
rename decile countryyear
save "Sumstat.dta", replace

******Isolate the 6 subpart, replace the variable name by the first obs, and merge to the Sumstat.dta"

forvalues i=1(1)7{
import delimited "Export déciles 6.csv", varnames(1) clear
drop if decile=="D01"|decile=="D02"|decile=="D03"|decile=="D04"|decile=="D05"|decile=="D06"|decile=="D07"|decile=="D08"|decile=="D09"|decile=="D10"
keep if countryyear=="Inequality Measures `i'"
gsort -inc1_mean_1
drop countryyear
missings dropvars, force

/*don't know why does not work when done only once*/
ds
	foreach v in `r(varlist)' {
	local try = strtoname(`v'[1]) 
     capture rename `v'  `try' 
	}
	ds
	foreach v in `r(varlist)' {
	local try = strtoname(`v'[1]) 
     capture rename `v'  `try' 
	}
	ds
	foreach v in `r(varlist)' {
	local try = strtoname(`v'[1]) 
     capture rename `v'  `try' 
	}
save "Sumstat`i'.dta", replace
merge 1:1 countryyear using "Sumstat.dta", gen(_merge`i')
save "Sumstat.dta", replace
}
drop _merge1-_merge7

***drop the obs containing the header****
drop if countryyear=="countryyear"

**destring all variables but the first
ds
foreach v in `r(varlist)' {
destring `v', replace
}
********generate country code and year*****
gen ccode = substr(countryyear, 1, 2)

gen year=substr(countryyear,3,2)
destring year, replace
replace year=year+1900 if year>50
replace year=year+2000 if year<50

kountry ccode, from(iso2c)
rename NAMES_STD country

*****save the data set and include OECD macro data*****
save "LIS Reducing Inequality Country.dta", replace

sort country year

merge 1:1 country year using "C:\Users\101625\Desktop\lis-tax-transfer\Stata\dta\allOECD2.dta"

save "LIS et OECD.dta", replace

*************include EPL index*********
import delimited "C:\Users\101625\Desktop\lis-tax-transfer\Stata\dta\EPL_OECD.csv", clear 

rename time year
rename value EPL
keep country year EPL

sort country year
save "EPL.dta", replace

use "LIS et OECD.dta", clear

merge 1:1 country year using "EPL.dta", gen(_merge2)

save "LIS et OECD.dta", replace

*************************************
*********Display the deciles ********
*************************************

import delimited "Export déciles.csv", varnames(1) clear
*rename (_all) (countryyear,decile,inc1_mean_1,inc1_min_1,inc1_max_1,inc2_mean_1,inc2_min_1,inc2_max_1,inc3_mean_1,inc3_min_1,inc3_max_1,inc4_mean_1,inc4_min_1,inc4_max_1,transfer_mean_1,transfer_min_1,transfer_max_1,tax_mean_1,tax_min_1,tax_max_1, inc1_mean_2,inc1_min_2,inc1_max_2,inc2_mean_2,inc2_min_2,inc2_max_2,inc3_mean_2,inc3_min_2,inc3_max_2,inc4_mean_2,inc4_min_2,inc4_max_2,transfer_mean_2,transfer_min_2,transfer_max_2,tax_mean_2,tax_min_2,tax_max_2,inc1_mean_3,inc1_min_3,inc1_max_3,inc2_mean_3,inc2_min_3,inc2_max_3,inc3_mean_3,inc3_min_3,inc3_max_3,inc4_mean_3,inc4_min_3,inc4_max_3,transfer_mean_3,transfer_min_3,transfer_max_3,tax_mean_3,tax_min_3,tax_max_3,inc1_mean_4,inc1_min_4,inc1_max_4,inc2_mean_4,inc2_min_4,inc2_max_4,inc3_mean_4,inc3_min_4,inc3_max_4,inc4_mean_4,inc4_min_4,inc4_max_4,transfer_mean_4,transfer_min_4,transfer_max_4,tax_mean_4,tax_min_4,tax_max_4, inc1_mean_5,inc1_min_5,inc1_max_5,inc2_mean_5,inc2_min_5,inc2_max_5,inc3_mean_5,inc3_min_5,inc3_max_5,inc4_mean_5,inc4_min_5,inc4_max_5,transfer_mean_5,transfer_min_5,transfer_max_5,tax_mean_5,tax_min_5,tax_max_5, inc1_mean_6,inc1_min_6,inc1_max_6,inc2_mean_6,inc2_min_6,inc2_max_6,inc3_mean_6,inc3_min_6,inc3_max_6,inc4_mean_6,inc4_min_6,inc4_max_6,transfer_mean_6,transfer_min_6,transfer_max_6,tax_mean_6,tax_min_6,tax_max_6)

keep if decile=="D01"|decile=="D02"|decile=="D03"|decile=="D04"|decile=="D05"|decile=="D06"|decile=="D07"|decile=="D08"|decile=="D09"|decile=="D10"

ds
foreach v in `r(varlist)' {
destring `v', replace
}

********generate country code and year*****
gen ccode = substr(countryyear, 1, 2)

gen year=substr(countryyear,3,2)
destring year, replace
replace year=year+1900 if year>50
replace year=year+2000 if year<50

kountry ccode, from(iso2c)
rename NAMES_STD country
*rename (countryyear decile inc1_mean_1_1 inc1_min_1_1 inc1_max_1_1 inc2_mean_1_1 inc2_min_1_1 inc2_max_1_1 inc3_mean_1_1 inc3_min_1_1 inc3_max_1_1 inc4_mean_1_1 inc4_min_1_1 inc4_max_1_1 transfer_mean_1_1 transfer_min_1_1 transfer_max_1_1 tax_mean_1_1 tax_min_1_1 tax_max_1_1  inc1_mean_1_2 inc1_min_1_2 inc1_max_1_2 inc2_mean_1_2 inc2_min_1_2 inc2_max_1_2 inc3_mean_1_2 inc3_min_1_2 inc3_max_1_2 inc4_mean_1_2 inc4_min_1_2 inc4_max_1_2 transfer_mean_1_2 transfer_min_1_2 transfer_max_1_2 tax_mean_1_2 tax_min_1_2 tax_max_1_2 inc1_mean_1_3 inc1_min_1_3 inc1_max_1_3 inc2_mean_1_3 inc2_min_1_3 inc2_max_1_3 inc3_mean_1_3 inc3_min_1_3 inc3_max_1_3 inc4_mean_1_3 inc4_min_1_3 inc4_max_1_3 transfer_mean_1_3 transfer_min_1_3 transfer_max_1_3 tax_mean_1_3 tax_min_1_3 tax_max_1_3 inc1_mean_1_4 inc1_min_1_4 inc1_max_1_4 inc2_mean_1_4 inc2_min_1_4 inc2_max_1_4 inc3_mean_1_4 inc3_min_1_4 inc3_max_1_4 inc4_mean_1_4 inc4_min_1_4 inc4_max_1_4 transfer_mean_1_4 transfer_min_1_4 transfer_max_1_4 tax_mean_1_4 tax_min_1_4 tax_max_1_4) (countryyear decile inc1_mean_1 inc1_min_1 inc1_max_1 inc2_mean_1 inc2_min_1 inc2_max_1 inc3_mean_1 inc3_min_1 inc3_max_1 inc4_mean_1 inc4_min_1 inc4_max_1 transfer_mean_1 transfer_min_1 transfer_max_1 tax_mean_1 tax_min_1 tax_max_1  inc1_mean_2 inc1_min_2 inc1_max_2 inc2_mean_2 inc2_min_2 inc2_max_2 inc3_mean_2 inc3_min_2 inc3_max_2 inc4_mean_2 inc4_min_2 inc4_max_2 transfer_mean_2 transfer_min_2 transfer_max_2 tax_mean_2 tax_min_2 tax_max_2 inc1_mean_3 inc1_min_3 inc1_max_3 inc2_mean_3 inc2_min_3 inc2_max_3 inc3_mean_3 inc3_min_3 inc3_max_3 inc4_mean_3 inc4_min_3 inc4_max_3 transfer_mean_3 transfer_min_3 transfer_max_3 tax_mean_3 tax_min_3 tax_max_3 inc1_mean_4 inc1_min_4 inc1_max_4 inc2_mean_4 inc2_min_4 inc2_max_4 inc3_mean_4 inc3_min_4 inc3_max_4 inc4_mean_4 inc4_min_4 inc4_max_4 transfer_mean_4 transfer_min_4 transfer_max_4 tax_mean_4 tax_min_4 tax_max_4)


/******* On génère maintenant des rapports interquantiles avec les vraies définitions**********/

encode(countryyear), gen(ccyy)
forvalues i=1/6{
forvalues j=1(4)9{
bysort ccyy (decile) : gen d`j'_inc`i'= inc`i'_max_`i'[`j']
}
}
forvalues i=1/6{
bysort ccyy (decile) : gen d9d1_inc`i' = d9_inc`i'/d1_inc`i'
bysort ccyy (decile) : gen d5d1_inc`i' = d5_inc`i'/d1_inc`i'
bysort ccyy (decile) : gen d9d5_inc`i' = d9_inc`i'/d5_inc`i'
}

bysort ccyy (decile) : gen reduc_d9d5_cotis=d9d5_inc3 - d9d5_inc6 /*Rappel inc6 : inc3 - cotis (employes et employeurs)*/
bysort ccyy (decile) : gen reduc_d9d5_tax=d9d5_inc6 - d9d5_inc4 

bysort ccyy (decile) : gen reduc_d5d1_cotis=d5d1_inc3 - d5d1_inc6 /*Rappel inc6 : inc3 - cotis (employes et employeurs)*/
bysort ccyy (decile) : gen reduc_d5d1_tax=d5d1_inc6 - d5d1_inc4 


bysort ccyy (decile) : gen reduc_d9d5_cotis_employeur=d9d5_inc3 - d9d5_inc5 /*Rappel inc6 : inc3 - cotis (employes et employeurs)*/
bysort ccyy (decile) : gen reduc_d9d5_cotis_salarie=d9d5_inc5 - d9d5_inc6/*Rappel inc6 : inc3 - cotis (employes et employeurs)*/

bysort ccyy (decile) : gen reduc_d5d1_cotis_employeur=d5d1_inc3 - d5d1_inc5
bysort ccyy (decile) : gen reduc_d5d1_cotis_salarie=d5d1_inc5 - d5d1_inc6



save "Export deciles.dta", replace

/*On fait quelques checks

list ccyy  if d1_inc1<500 
list ccyy d1_inc2 if d1_inc2<100/*ie10 : d1 à 0*/
list ccyy d1_inc3 if d1_inc3<100/*0*/
list ccyy d1_inc4 if d1_inc3<100/*0*/

list ccyy transfer_mean_1 transfer_mean_2 transfer_mean_3 transfer_mean_4 if transfer_mean_1<-0.01 | transfer_mean_2<-0.01 | transfer_mean_3<-0.01 | transfer_mean_4<-0.01/*0 : c'est rassurant...*/
list ccyy transfer_min_1 transfer_min_2 transfer_min_3 transfer_min_4 if transfer_min_1<-0.01 | transfer_min_2<-0.01 | transfer_min_3<-0.01 | transfer_min_4<-0.01/*Plus inquiétant : pourquoi des transferts négatifs? 
Pour les gros transferts négatifs, c'est surtout chez les nordiques : danemark, finlande, netherlands, norvège
: 
Particulièrement négatif (plusieurs centaines d'euros) :  Dk07 (-2135.4629 parfois), Dk10 ( -5608.7031 ) fi00 (-1387.2837 ) fi04 ( -2359.4973 ) fi07 (-2078.8884) fi10 (-1113.8242) nl07 (-13938.366 !!!!!) no07 (-37380.727) no10
 (-38165.586 )
 
 Je pense que ça vient de la soustraction des pensions d'assurance des transferts : 
 ITSIL (long-term work-related insurance transfers). Pourquoi d'ailleurs on laisse les assurances de CT ?
 
*/

