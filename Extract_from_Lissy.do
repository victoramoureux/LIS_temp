*************************************************************
* Define globals
*************************************************************

global datasets "at04 au03 au08 au10 ca04 ca07 ca10 ch00 ch02 ch04 cz02 cz04 cz07 cz10 de00 de04 de07 de10 dk00 dk04 dk07 dk10 ee10 es07 es10 es13 fi00 fi04 fi07 fi10 fr00 fr05 fr10 gr07 gr10 ie04 ie07 ie10 il10 il12 is04 is07 is10 it04 it08 it10 jp08 kr06 lu04 lu07 lu10 nl04 nl07 nl10 nl99 no00 no04 no07 no10 pl04 pl07 pl10 pl13 pl99 se00 se05 sk04 sk07 sk10 uk99 uk04 uk07 uk10 us00 us04 us07 us10 us13 at00 be00 gr00 hu05 hu07 hu09 hu12 hu99 ie00 it00 lu00 mx00 mx02 mx04 mx08 mx10 mx12 mx98 si10"

global net_datasets "at00 be00 gr00 hu05 hu07 hu09 hu12 hu99 ie00 it00 lu00 mx00 mx02 mx04 mx08 mx10 mx12 mx98 si10" // Removed es00 and it98 in this version since they contain dupicates and missing values respectively in pil.

global pvars "pid hid dname pil pxit pxiti pxits age emp relation"

global hvars "hid dname nhhmem dhi nhhmem17 nhhmem65 hwgt"

global hvarsflow "hil hic pension hits hitsil hitsup hitsap hxit hxiti hxits hc hicvip dhi hitsilmip hitsilo hitsilep hitsilwi hitsilepo hitsilepd hitsileps" // Local currency, given in the datasets

global hvarsnew "hsscer hsscee" // Local currency, imputed

global hvarsinc "inc1 inc2 inc3 inc4 inc5 inc6 tax transfer allpension pubpension pripension hssc" // Summation / imputed after PPP conversion /*VA add inc5 inc6*/

global fixpensions_datasets1 "at04 ee10 gr00 lu04 nl04 no04 no10 se00 se05"  // hitsil missing, hicvip defined

global fixpension_datasets2 "au08 au10 ca04 ca07 ca10 is04 is07 is10 jp08 no00 no07 si10" // hitsil missing, hicvip missing

global fixpension_datasets3 "ie04 ie07 ie10 uk99 uk04 uk07 uk10"


*************************************************************
* Program: Generate SSC variables from person level dataset
*************************************************************

program define merge_ssc
  merge m:1 dname using "$mydata/vamour/ssc_20180606.dta", keep(match) nogenerate
end

program define gen_employee_ssc
  * Generate Employee Social Security Contributions
  /*In general, PIL is gross in the sense of wage so it's correct to just multiply by the rate applied to the gross salary*/
  gen psscee=.
  replace psscee = pil*ee_r1
  replace psscee = (pil-ee_c1)*ee_r2 + ee_r1*ee_c1  if pil>ee_c1 & ee_c1!=.
  replace psscee = (pil-ee_c2)*ee_r3 + ee_r2*(ee_c2 - ee_c1) + ee_r1*ee_c1 if pil>ee_c2 & ee_c2!=.
  replace psscee = (pil-ee_c3)*ee_r4 + ee_r3*(ee_c3 - ee_c2) + ee_r2*(ee_c2 - ee_c1) + ee_r1*ee_c1 if pil>ee_c3 & ee_c3!=.
  replace psscee = (pil-ee_c4)*ee_r5 + ee_r4*(ee_c4 - ee_c3) + ee_r3*(ee_c3 - ee_c2) + ee_r2*(ee_c2 - ee_c1) + ee_r1*ee_c1 if pil>ee_c4 & ee_c4!=.
  /*replace psscee = (pil-ee_c5)*ee_r6 + ee_r5*(ee_c5 - ee_c4) + ee_r4*(ee_c4 - ee_c3) + ee_r3*(ee_c3 - ee_c2) + ee_r2*(ee_c2 - ee_c1) + ee_r1*ee_c1  if pil>ee_c5 & ee_c5!=.*/ /*VA change the stata file*/
end

program define gen_employer_ssc
  * Generate Employer Social Security Contributions
  
  gen psscer=.
  replace psscer = pil*er_r1
  replace psscer = (pil-er_c1)*er_r2 + er_r1*er_c1  if pil>er_c1 & er_c1!=.
  replace psscer = (pil-er_c2)*er_r3 + er_r2*(er_c2 - er_c1) + er_r1*er_c1 if pil>er_c2 & er_c2!=.
  replace psscer = (pil-er_c3)*er_r4 + er_r3*(er_c3 - er_c2) + er_r2*(er_c2 - er_c1) + er_r1*er_c1 if pil>er_c3 & er_c3!=.
  replace psscer = (pil-er_c4)*er_r5 + er_r4*(er_c4 - er_c3) + er_r3*(er_c3 - er_c2) + er_r2*(er_c2 - er_c1) + er_r1*er_c1 if pil>er_c4 & er_c4!=.
 /* replace psscer = (pil-er_c5)*er_r6 + er_r5*(er_c5 - er_c4) + er_r4*(er_c4 - er_c3) + er_r3*(er_c3 - er_c2) + er_r2*(er_c2 - er_c1) + er_r1*er_c1  if pil>er_c5 & er_c5!=.*/ /*VA change the Stata file*/
end

program define convert_ssc_to_household_level
  * Convert variables to household level
  bysort hid: egen hsscee=total(psscee)
  bysort hid: egen hsscer=total(psscer)
  *create household activ age dummy*
  activage_household
  * Keep only household level SSC and household id and activage dummy
  keep hid hsscee hsscer hhactivage
  drop if hid==.
  duplicates drop hid, force
end

program define activage_household
	*create a dummy variable taking 1 if head of household btw 25 and 59
	gen headactivage=1 if age>24 & age<60 & relation==1000
	replace headactivage=0 if headactivage!=1
	bys hid: egen hhactivage=total(headactivage)
	drop headactivage
end

program define gen_pvars
  merge_ssc
  gen_employee_ssc
  manual_corrections_employee_ssc
  gen_employer_ssc
  manual_corrections_employer_ssc
  convert_ssc_to_household_level
end

program define FR_gen_pvars
  merge_ssc
  * Impute individual level income tax from household level income tax
  bysort hid: egen hemp = total(emp) , missing // missing option to set a total of all missing values to missing rather than zero.
  drop pxiti
  gen pxiti = hxiti/hemp
  replace pxiti =. if emp!=1
  **IMPORTANT**Generate Employee Social Security Contributions
  /*VA We assume that the original INSEE survey provides information about actual "net" wages in the sense "net of all contributions" and not in the sense of "declared income", which contains non deductible CSG. If not, one should 
  remove this rate in the excel file and add it manually after we have the gross income*/

  gen psscee=.
  replace psscee = pil*ee_r1/(1-ee_r1) if pil>0 & pil<=(ee_c1 - ee_r1*ee_c1) 
  replace psscee = 1/(1-ee_r2)*(ee_r2*(pil - ee_c1) + ee_r1*ee_c1) if pil>(ee_c1 - ee_r1*ee_c1) & pil<=(ee_c2 - ee_r1*ee_c1 - ee_r2*(ee_c2-ee_c1))
  replace psscee = 1/(1-ee_r3)*(ee_r3*(pil - ee_c2) + ee_r1*ee_c1 + ee_r2*(ee_c2-ee_c1)) if pil>(ee_c2 - ee_r2*(ee_c2-ee_c1) - ee_r1*ee_c1) & pil<=(ee_c3 - ee_r3*(ee_c3-ee_c2) - ee_r2*(ee_c2-ee_c1) - ee_r1*ee_c1)
  replace psscee = 1/(1-ee_r4)*(ee_r4*(pil - ee_c3) + ee_r1*ee_c1 + ee_r2*(ee_c2-ee_c1) + ee_r3*(ee_c3 - ee_c2)) if pil>(ee_c3 - ee_r3*(ee_c3-ee_c2) - ee_r2*(ee_c2-ee_c1) - ee_r1*ee_c1)

  **IMPORTANT**Convert French datasets from net to gross

  replace pil=pil+pxiti+psscee
  gen_employer_ssc
  manual_corrections_employer_ssc
  convert_ssc_to_household_level
end

program define IT_gen_pvars
  merge_ssc
  **IMPORTANT**Convert Italian datasets from net to gross
  replace pil=pil+pxit
  gen psscee=. // hxits is defined for italy, so no need to impute
  gen_employer_ssc
  convert_ssc_to_household_level
end

program define NET_gen_pvars
  * Impute taxes for net datasets
  nearmrg dname using "$mydata/molcke/net_20161101.dta", nearvar(pil) lower keep(match) nogenerate
  * Convert variables to household level
  bysort hid: egen hxiti=total(pinctax)
  bysort hid: egen hsscee=total(psscee)
  bysort hid: egen hsscer=total(psscer)
    *create household activ age dummy*
  activage_household
  * Keep only household level SSC and household id
  keep hid hsscee hsscer hxiti hhactivage
  drop if hid==.
  duplicates drop hid, force
end

***************************************************************************
* Helper Program: Manual corrections
***************************************************************************

program define manual_corrections_employee_ssc
  * Manual corrections for certain datasets (Employee Social Security Contributions)

  *Belgium 2000 BE00
  replace psscee=psscee-2600 if pil>34000 & pil<=42500 & dname=="be00"
  replace psscee=psscee-(2600-0.4*(pil-42500)) if pil>42500 & pil<=4900 & dname=="be00"
  bysort hid: egen hil=total(pil) if dname=="be00"
  replace psscee=psscee+0.09*hil if hil>750000 & hil<=850000 & dname=="be00"
  replace psscee=psscee+9000+0.013*hil if hil>850000 & hil<=2426924 & dname=="be00"
  replace psscee=psscee+29500 if hil>2426924 & dname=="be00"
  *Denmark 2007 DK07
  replace psscee=psscee+8052+975.6 if pil>0 & dname=="dk07"
  *Denmark 2010 DK10
  replace psscee=psscee+10244 if pil>0 & dname=="dk10"
  *Greece 2000 GR00
  replace psscee=0.159*6783000 if pil>6783000 & age>29 & dname=="gr00" //it would be betzter if I used year of birth
  *Greece 2004 GR04
  replace psscee=0.16*24699 if pil>24699 & age>33 & dname=="gr04"
  *Greece 2007 GR07
  replace psscee=0.16*27780 if pil>27780  & age>36 & dname=="gr07"
  *Greece 2010 GR10
  replace psscee=0.16*29187 if pil>29187  & age>39 & dname=="gr10"
  *Iceland 2007 IS07
  replace psscee=6314 if pil>ee_c1 & dname=="is07" //Should there also be an age restriction like in 2010?
  *Iceland 2010 IS10
  replace psscee=8400+17200 if pil>ee_c1 & age>=16 & age<=70 & dname=="is10"
end

program define manual_corrections_employer_ssc
  * Manual corrections for certain datasets (Employer Social Security Contributions)
    *VA: Germany global rate for low income (De): 2004
  replace psscer = 0.25*pil if pil<4800 & dname=="de04" | dname=="de07"
  *Germany 2010 de10 (VA)
  replace psscer = 0.30*pil if pil<4800 & dname=="de10" 

  *Estonia 2010 ee10
  replace psscer = psscer + 17832 if pil>0 & dname=="ee10"
  *Hungary 2005 hu05 VA
  replace psscer = psscer + 3450*10 + 1950*2 if pil>0 & dname=="hu05"
  *Hungary 2007 2009 hu07 hu09 VA
  replace psscer = psscer + 1950*12 if pil>0 & dname=="hu07"|dname=="hu09"
  *Ireland 2000 ie00
  replace psscer=pil*.085 if  pil<14560 & dname=="ie00" // I could have easily included these changes for Ireland in the rates and ceilings.
  *Ireland 2004 ie04
  replace psscer=pil*.085 if  pil<18512 & dname=="ie04"
  *Ireland 2007 ie07
  replace psscer=pil*.085 if  pil<18512 & dname=="ie07"
  *Ireland 2010 ie10
  replace psscer=pil*.085 if  pil<18512 & dname=="ie10"
  *France 2000 fr00 (measured in Francs, not Euros)
  replace psscer=psscer-(0.182*pil) if pil<=83898 & dname=="fr00" /*VA 83 898 = average annual Smic for the year 2000*/ 
  replace psscer=psscer-(0.55*(111584.34-pil)) if pil>83898 & pil<=111584.34 & dname=="fr00" /*VA I think it is 1.3 Smic instead of 1.33 and a .607 negative slope*/
 
  *France 2005 fr05
  replace psscer=psscer-((0.26/0.6)*((24692.8/pil)-1)*pil) if pil>15433 & pil<24692.8 & dname=="fr05" //I am not sure I have this adjustment correct. VA I don't understand why the Smic is at 15 433
  *France 2010 fr10
  replace psscer=psscer-((0.26/0.6)*((25800.32/pil)-1)*pil) if pil>16125 & pil<25800.32 & dname=="fr10" /*VA Smic ok*/
  
  *Mexico 2000 mx00 VA
  replace psscer=psscer + 0.152*35.12*365 if pil>0 & dname=="mx00"
  replace psscer=psscer + 0.0502*(pil-3*35.12*365) if pil>3*35.12*365 & dname=="mx00"
  *Mexico 2002 mx02 VA
  replace psscer=psscer + 0.165*39.74*365 if pil>0 & dname=="mx02"
  replace psscer=psscer + 0.0404*(pil-3*39.74*365) if pil>3*39.74*365 & dname=="mx02"
 *Mexico 2004 mx04 VA
  replace psscer=psscer + 0.178*45.24*365 if pil>0 & dname=="mx04"
  replace psscer=psscer + 0.0306*(pil-3*45.24*365) if pil>3*45.24*365 & dname=="mx04"
 *Mexico 2008 mx08 VA
  replace psscer=psscer + 0.204*52.59*365 if pil>0 & dname=="mx08"
  replace psscer=psscer + 0.011*(pil-3*52.59*365) if pil>3*52.59*365 & dname=="mx08"
 *Mexico 2010 mx10 VA
  replace psscer=psscer + 0.204*57.46*365 if pil>0 & dname=="mx10"
  replace psscer=psscer + 0.011*(pil-3*57.46*365) if pil>3*57.46*365 & pil<25*57.46*365 & dname=="mx10"
  replace psscer=psscer + 0.011*((25-3)*57.46*365)	 if pil>25*57.46*365 & dname=="mx10"
 *Mexico 2012 mx12 VA
  replace psscer=psscer + 0.204*62.33*365 if pil>0 & dname=="mx10"
  replace psscer=psscer + 0.011*(pil-3*62.33*365) if pil>3*62.33*365 & pil<25*62.33*365 & dname=="mx10"
  replace psscer=psscer + 0.011*((25-3)*62.33*365)	 if pil>25*62.33*365 & dname=="mx10"

  *Netherlands 1999 nl99 VA
  replace psscer=psscer + 0.0585*pil  if pil>0 & pil<54810 & dname=="nl99"
  replace psscer=psscer + 0.0585*54810  if pil>0 & pil<64300 & dname=="nl99"
  *Netherlands 2004 nl04 VA
  replace psscer=psscer + 0.0675*pil  if pil>0 & pil<29493 & dname=="nl04"
  replace psscer=psscer + 0.0675*29493  if pil>0 & pil<32600 & dname=="nl04"
 

end

***************************************************************************
* Program: Apply PPP conversions and equivalence scales to flow variables
***************************************************************************

program define ppp_equiv
  * Define PPP conversions to 2011 international dollars (ppp)
  merge m:1 dname using "$mydata/molcke/ppp.dta", keep(match) nogenerate

  * Complete the PPP conversions and equivalence scales with replace commands
  foreach var in $hvarsflow $hvarsnew {
    replace `var' = (`var'*ppp_2011_usd)/(nhhmem^0.5)
    }

  * Trim and bottom code
    * Step 1
    drop if dhi<=0
    * Step 2
    replace hsscer=0 if hsscer<0 // Employer
    replace hsscee=0 if hsscee<0 // Employee
    * Step 3
    // completed within the inc_and_decile program
end


*******************************************************************
* Helper Program: Define the different stages of income and deciles
*******************************************************************

program define inc_and_decile

  gen inc1 = marketincome
  gen inc2 = marketincome + allpension
  gen inc3 = marketincome + allpension + transfer
  gen inc4 = marketincome + allpension + transfer - tax

 /*VA display des indicateurs de revenus bruts et nets.
 NB on appelle inc5 et inc6 mais si on intègre TVA il faudra les nommers inc6 et inc7  */
  gen inc5 = marketincome + allpension + transfer - hsscer /*revenus brut au sens français*/
  gen inc6 = marketincome + allpension + transfer - hsscer - hxits  /*revenus net au sens français*/
  * Trim and bottom code
  // The preceding steps are in the ppp_equiv program
  * Step 3
  foreach var in $hvarsflow $hvarsnew {
  replace `var' = 0 if `var' < 0
  }
  * Define the income deciles for various concepts of income
  /*VA modif : loop*/
  forvalues i = 1/6{
  xtile decile_`i' = inc`i' [w=hwgt*nhhmem], nquantiles(10) // already corrected for household size by ppp_equiv
  xtile hhaa_decile_`i' = inc`i' [w=hwgt*nhhmem] if hhactivage==1, nquantiles(10) // already corrected for household size by ppp_equiv
}
end

**************************************************
* Program: Define taxes and transfer variables
**************************************************

program define def_tax_and_transfer
  * Use the imputed data if employee social security contributions is not available
  replace hxits=hsscee if hxits==.
  * For certain countries, hitsil is missing, but some of the hitsil subcategories are defined
  egen hitsil2 = rowtotal(hitsilmip hitsilo hitsilep hitsilwi hitsilepo hitsilepd hitsileps)
  replace hitsil = hitsil2 if hitsil==.
  * Set the following variables to zero if they are missing, since these variables do not apply to many countries or were not included in their survey.
  replace hitsil=0 if hitsil==.
  replace hitsap=0 if hitsap==.
  replace hitsup=0 if hitsup==.
  * I will set the following variables to zero if they missing, but this is where I am going to need careful analysis of the missing values.
  replace hicvip=0 if hicvip==.
  replace hic=0 if hic==.
  replace pension=0 if pension==.
  * Rather use hxit in the income definitions
  replace hxit = hxiti + hxits if hxit==.
  * Define the components of the income stages
  gen pubpension = hitsil + hitsup
  gen pripension = hicvip
  gen allpension = pension - hitsap
  gen transfer = hits - pubpension
  gen tax = hxit + hsscer
  gen hssc = hxits + hsscer
  gen marketincome = hil + (hic-hicvip) + hsscer

  inc_and_decile

end

***************************************************************************
* Program: Adjustments to pensions for certain countries
***************************************************************************

/* It is noted in LIS that there is some difficulty in defining pension related
transfers in Sweden and Norway. The following code adjusts the definitions of
the income variables for use in Sweden and Norway */

program define fix_pensions_type1
  drop pubpension transfer inc1 inc2 inc3 inc4 inc5 inc6 decile_1 decile_2 decile_3 decile_4 decile_5 decile_6 hhaa_decile_1 hhaa_decile_2 hhaa_decile_3 hhaa_decile_4 hhaa_decile_5 hhaa_decile_6/*VA ajout des  decile à drop*/
  gen pubpension = pension - hicvip - hitsap
  *gen pripension = hicvip // No change
  *gen allpension = pension - hitsap // No change
  gen transfer = hits - pubpension
  *gen tax = hxit + hsscer // No change
  *gen marketincome = hil + (hic-hicvip) + hsscer // No change

  inc_and_decile

end

***************************************************************************
* Program: Adjustments to pensions for UK and Ireland
***************************************************************************

/* In the preceding income definitions, UK and Ireland have transfers that
seem to be too high. We propose moving HITSAP (old-age, disability assistance
pensions, a subcategory of assistance benefits) out of transfers, and into
pensions.  */

program define fix_pensions_type3
  drop pubpension allpension transfer inc1 inc2 inc3 inc4 inc5 inc6 decile_1 decile_2 decile_3 decile_4 decile_5 decile_6 hhaa_decile_1 hhaa_decile_2 hhaa_decile_3 hhaa_decile_4 hhaa_decile_5 hhaa_decile_6
  gen pubpension = hitsil + hitsup + hitsap // Added "+hitsap"
  *gen pripension = hicvip // No change
  gen allpension = pension // Removed "-hitsap"
  gen transfer = hits - pubpension
  *gen tax = hxit + hsscer // No change
  *gen marketincome = hil + (hic-hicvip) + hsscer // No change

  inc_and_decile

end

***************************************************************************
* Program: Adjustments to tax for France
***************************************************************************

program define FR_def_tax_and_transfer
  drop tax inc1 inc2 inc3 inc4 inc5 inc6  decile_1 decile_2 decile_3 decile_4 decile_5 decile_6 hhaa_decile_1 hhaa_decile_2 hhaa_decile_3 hhaa_decile_4 hhaa_decile_5 hhaa_decile_6 marketincome
  * Impute the taxes CSG and CRDS
  FR_tax_CSG_CRDS
  * Define the components of the income stages
  gen tax = hxiti + hxits + hsscer + hic_csg_crds + pension_csg_crds
  * For France, incomes are reported net of ssc, but gross of income tax
  gen marketincome = hil + (hic-hicvip) + hsscer + hic_csg_crds + hxits + pension_csg_crds

  inc_and_decile

end

program define FR_tax_CSG_CRDS
  * Labour income
  // CSG and CRDS on labour income is imputed within Employee SSC
  * Capital income
  gen hic_csg_crds = hic * 0.08 if dname =="fr00"
  replace hic_csg_crds = hic * 0.087 if dname =="fr05"
  replace hic_csg_crds = hic * 0.087  if dname =="fr10" /*VA changer le taux en 0.087 au lieu de 0.08*/
  * Pensions
    *Family share
    gen N = (nhhmem - nhhmem17)
    replace N = 2 + ((nhhmem - nhhmem17)-2) / 2 if (nhhmem - nhhmem17)>2
    gen C = nhhmem17 / 2
    replace C = 1 + (nhhmem17 - 2) if nhhmem17>2
    gen familyshare = N + C
    drop N C
	
    *Imputation 
	
	/*VA correction : je pense qu'il y a un certain nombre d'erreurs dans le prog initial : 
	(i) avant 2015, le critère de taux réduit était un critère d'imposabilité et non de revenu fiscal de référence (RFR) qui ne vaut que pour le critère d'exonération :
		- taux réduit : être au-dessus du seuil d'exo mais pas imposable
		- taux plein : être au-dessuss du seuil d'exo et imposable
		NB : si LIS est poursuivi après 2015 (par exemple avec BdF 2016) il faudra changer ça et bien mettre les deux critères de RFR
		
	(ii) vu le concept de revenu en France (i.e. net), on peut calculer le RFR : il s'agit des revenus nets + CSG non déductible, moins abattements. Vu que la CSG à taux réduit est intégralement déductible,
	cela facilite les choses : pour nos retraités, retraite au sens du RFR = retraite nette - abattements ... Les abattements son multiples mais j'ai mis le principal : abattement de 10 % pour frais pros en l'appliquant au salaire augmenté de la CSG non déductible et 
	aux pensions (pas au capital).
	Il y a aussi des abattements spéciaux personnes âgées  mais ceux ci sont un peu compliqués à calculer et je ne suis pas sûr qu'ils rentrent dans le concept du RFR (je crois que c'est la différence entre "brut" au sens des impôts et RFR...
	
	
	(iii) la parenthèse est au mauvais endroit et je pense que du coup personne n'est à la CSG parmi les retraités
	
	(iv) Le seuil de RFR par demi-part supplémentaire doit être multiplié par un facteur 2 : en effet, chaque demi-part compte pour "une" unité : ex : 1 part supplémentaire = 2 demi-parts => 2*le seuil pour une demi-part sup
	
	(v) Si les pensions initiales sont bien "nettes" au sens sans CSG, il faut faire la règle de 3 inversée : pension nette = (1-tx_CSG)*brute d'où pension brute = 1/(1-tx_CSG)*pension nette et Montant de CSG =tx_CSG/(1-tx_CSG)*pension nette
	
	*/
    gen pension_csg_crds = 0
	gen hil_temp=hil-hxiti-hsscee /*On regarde bien le salaire net pour calculer le RFR*/
    /*replace pension_csg_crds = 0.043*(hitsil + hitsup) if hil > (6584+(familyshare - 1))*1759 & dname=="fr00" // 2002 figures deflated to 2000 prices using WDI CPI
    replace pension_csg_crds = 0.067*(hitsil + hitsup) if hil > (7796+(familyshare - 1))*2120 & dname=="fr00" // 2002 figures deflated to 2000 prices using WDI CPI
    replace pension_csg_crds = 0.043*(hitsil + hitsup) if hil > (7165+(familyshare - 1))*1914 & dname=="fr05"
    replace pension_csg_crds = 0.071*(hitsil + hitsup) if hil > (8492+(familyshare - 1))*2308 & dname=="fr05"
    replace pension_csg_crds = 0.043*(hitsil + hitsup) if hil > (9876+(familyshare - 1))*2637 & dname=="fr10"
    replace pension_csg_crds = 0.071*(hitsil + hitsup) if hil > (11793+(familyshare - 1))*3178 & dname=="fr10"*/
	
	replace pension_csg_crds = 0.043/(1-0.043)*(hitsil + hitsup) if ((hil_temp/(1-0.024*0.97) + hitsil + hitsup)*0.9 + hic) > (6584+2*(familyshare - 1)*1759) & hxit<=0 & dname=="fr00" // 2002 figures deflated to 2000 prices using WDI CPI
    replace pension_csg_crds = 0.067/(1-0.067)*(hitsil + hitsup) if ((hil_temp/(1-0.024*0.97) + hitsil + hitsup)*0.9 + hic) > (6584+2*(familyshare - 1)*1759) & hxit>0 & dname=="fr00" // 2002 figures deflated to 2000 prices using WDI CPI
    
	replace pension_csg_crds = 0.043/(1-0.043)*(hitsil + hitsup) if ((hil_temp/(1-0.024*0.97) + hitsil + hitsup)*0.9 + hic) > (7165+2*(familyshare - 1)*1914) & hxit<=0 & dname=="fr05"
    replace pension_csg_crds = 0.071/(1-0.071)*(hitsil + hitsup) if ((hil_temp/(1-0.024*0.97)+ hitsil + hitsup)*0.9 + hic) >  (7165+2*(familyshare - 1)*1914) & hxit>0 & dname=="fr05"
   
	replace pension_csg_crds = 0.043/(1-0.043)*(hitsil + hitsup) if ((hil_temp/(1-0.024*0.97) + hitsil + hitsup)*0.9 + hic) > (9876+2*(familyshare - 1)*2637) & hxit<=0 & dname=="fr10"
    replace pension_csg_crds = 0.071/(1-0.071)*(hitsil + hitsup) if ((hil_temp/(1-0.024*0.97) + hitsil + hitsup)*0.9 + hic) > (9876+2*(familyshare - 1)*2637) & hxit>0& dname=="fr10"
	
	drop hil_temp
	/*Warning : à partir de 2011 (i.e. pour le prochain LIS, l'abattement CSG activité passe à 1.75 %*/
end

***************************************************************
* Program: Correct dhi (disposable household income) for France
***************************************************************

/* Notes: For France particularly, dhi is provided gross of income taxes, even
though the income tax variable is available. Ths is because income taxes are
collected once per year, directly from households. The income tax variable in
LIS is the amount of the previous year's tax. So it is just a proxy of current
income tax. Here we compute the dhi net of income tax */

program define correct_dhi
  gen hxiti_temp = hxiti
 * replace hxiti_temp = 0 if hxiti<0
  replace hxiti_temp = 0 if hxit==.
  replace dhi = dhi - hxiti_temp
end


**********************************************************
* Output: Loop over datasets and output summary statistics
**********************************************************

foreach ccyy in $datasets {
  quietly use $pvars using $`ccyy'p, clear
  local cc : di substr("`ccyy'",1,2)
  if "`cc'" == "fr" {
    quietly merge m:1 hid using "$`ccyy'h", keep(match) keepusing(hxiti) nogenerate
    quietly FR_gen_pvars
  }
  else if "`cc'" == "it" {
    quietly merge m:1 hid using "$`ccyy'h", keep(match) keepusing(hxiti) nogenerate
    quietly IT_gen_pvars
  }
  else if strpos("$net_datasets","`ccyy'") > 0 {
    quietly NET_gen_pvars
  }
  else {
    quietly gen_pvars
  }
  
  
  quietly merge 1:1 hid using $`ccyy'h, keepusing($hvars $hvarsflow) nogenerate
  if "`cc'" == "fr" {
    quietly correct_dhi
  }
  quietly ppp_equiv
  quietly def_tax_and_transfer
  if "`cc'" == "fr" {
    quietly FR_def_tax_and_transfer
  }
  foreach certain_ccyy in $fixpensions_datasets1 {
    quietly fix_pensions_type1 if "`ccyy'" == "`certain_ccyy'"
  }
  foreach certain_ccyy in $fixpensions_datasets3 {
    quietly fix_pensions_type3 if "`ccyy'" == "`certain_ccyy'"
  }
  foreach var in $hvarsinc $hvarsflow $hvarsnew {
    quietly capture sgini `var' [aw=hwgt*nhhmem]
    local `var'_gini = r(coeff)
	quietly capture sgini `var' [aw=hwgt*nhhmem] if hhactivage==1
    local hhaa_`var'_gini = r(coeff)
    quietly sum `var' [w=hwgt*nhhmem]
    local `var'_mean = r(mean)
	quietly sum `var' [w=hwgt*nhhmem] if hhactivage==1
    local hhaa_`var'_mean = r(mean)
	/*Bien rajouter inc5 et inc6*/
    foreach sortvar in inc1 inc2 inc3 inc4 inc5 inc6 {
      quietly capture sgini `var' [aw=hwgt*nhhmem], sortvar(`sortvar')
      local `var'conc_`sortvar' = r(coeff)
	  quietly capture sgini `var' [aw=hwgt*nhhmem] if hhactivage==1, sortvar(`sortvar')	
      local hhaa_`var'conc_`sortvar' = r(coeff)
      }
    /*VA modif : boucle par catégorie de décile*/
	forvalues i = 1/6{
		forvalues num = 1/10 {
			quietly sum `var' [w=hwgt*nhhmem] if decile_`i'==`num'
			local `var'_mean_`num'_`i' = r(mean)
			local `var'_min_`num'_`i' = r(min)
			local `var'_max_`num'_`i' = r(max)
      }
	 }
   }
   /*VA modif du display : on crée un tableau avec 78 colonnes*/
     if "`ccyy'" == "at04" di "countryyear,decile,inc1_mean_1,inc1_min_1,inc1_max_1,transfer_mean_1,transfer_min_1,transfer_max_1,tax_mean_1,tax_min_1,tax_max_1,inc2_mean_2,inc2_min_2,inc2_max_2,transfer_mean_2,transfer_min_2,transfer_max_2,tax_mean_2,tax_min_2,tax_max_2,inc3_mean_3,inc3_min_3,inc3_max_3,transfer_mean_3,transfer_min_3,transfer_max_3,tax_mean_3,tax_min_3,tax_max_3,inc4_mean_4,inc4_min_4,inc4_max_4,transfer_mean_4,transfer_min_4,transfer_max_4,tax_mean_4,tax_min_4,tax_max_4,inc5_mean_5,inc5_min_5, inc5_max_5,transfer_mean_5,transfer_min_5,transfer_max_5,tax_mean_5,tax_min_5,tax_max_5,inc6_mean_6,inc6_min_6,inc6_max_6,transfer_mean_6,transfer_min_6,transfer_max_6,tax_mean_6,tax_min_6,tax_max_6"
	 di "`ccyy',D01,`inc1_mean_1_1',`inc1_min_1_1',`inc1_max_1_1',`transfer_mean_1_1',`transfer_min_1_1',`transfer_max_1_1',`tax_mean_1_1',`tax_min_1_1',`tax_max_1_1',`inc2_mean_1_2',`inc2_min_1_2',`inc2_max_1_2',`transfer_mean_1_2',`transfer_min_1_2',`transfer_max_1_2',`tax_mean_1_2',`tax_min_1_2',`tax_max_1_2',`inc3_mean_1_3',`inc3_min_1_3',`inc3_max_1_3',`transfer_mean_1_3',`transfer_min_1_3',`transfer_max_1_3',`tax_mean_1_3',`tax_min_1_3',`tax_max_1_3',`inc4_mean_1_4',`inc4_min_1_4',`inc4_max_1_4',`transfer_mean_1_4',`transfer_min_1_4',`transfer_max_1_4',`tax_mean_1_4',`tax_min_1_4',`tax_max_1_4',`inc5_mean_1_5',`inc5_min_1_5',`inc5_max_1_5',`transfer_mean_1_5',`transfer_min_1_5',`transfer_max_1_5',`tax_mean_1_5',`tax_min_1_5',`tax_max_1_5',`inc6_mean_1_6',`inc6_min_1_6',`inc6_max_1_6',`transfer_mean_1_6',`transfer_min_1_6',`transfer_max_1_6',`tax_mean_1_6',`tax_min_1_6',`tax_max_1_6'"
     di "`ccyy',D02,`inc1_mean_2_1',`inc1_min_2_1',`inc1_max_2_1',`transfer_mean_2_1',`transfer_min_2_1',`transfer_max_2_1',`tax_mean_2_1',`tax_min_2_1',`tax_max_2_1',`inc2_mean_2_2',`inc2_min_2_2',`inc2_max_2_2',`transfer_mean_2_2',`transfer_min_2_2',`transfer_max_2_2',`tax_mean_2_2',`tax_min_2_2',`tax_max_2_2',`inc3_mean_2_3',`inc3_min_2_3',`inc3_max_2_3',`transfer_mean_2_3',`transfer_min_2_3',`transfer_max_2_3',`tax_mean_2_3',`tax_min_2_3',`tax_max_2_3',`inc4_mean_2_4',`inc4_min_2_4',`inc4_max_2_4',`transfer_mean_2_4',`transfer_min_2_4',`transfer_max_2_4',`tax_mean_2_4',`tax_min_2_4',`tax_max_2_4',`inc5_mean_2_5',`inc5_min_2_5',`inc5_max_2_5',`transfer_mean_2_5',`transfer_min_2_5',`transfer_max_2_5',`tax_mean_2_5',`tax_min_2_5',`tax_max_2_5',`inc6_mean_2_6',`inc6_min_2_6',`inc6_max_2_6',`transfer_mean_2_6',`transfer_min_2_6',`transfer_max_2_6',`tax_mean_2_6',`tax_min_2_6',`tax_max_2_6'"
     di "`ccyy',D03,`inc1_mean_3_1',`inc1_min_3_1',`inc1_max_3_1',`transfer_mean_3_1',`transfer_min_3_1',`transfer_max_3_1',`tax_mean_3_1',`tax_min_3_1',`tax_max_3_1',`inc2_mean_3_2',`inc2_min_3_2',`inc2_max_3_2',`transfer_mean_3_2',`transfer_min_3_2',`transfer_max_3_2',`tax_mean_3_2',`tax_min_3_2',`tax_max_3_2',`inc3_mean_3_3',`inc3_min_3_3',`inc3_max_3_3',`transfer_mean_3_3',`transfer_min_3_3',`transfer_max_3_3',`tax_mean_3_3',`tax_min_3_3',`tax_max_3_3',`inc4_mean_3_4',`inc4_min_3_4',`inc4_max_3_4',`transfer_mean_3_4',`transfer_min_3_4',`transfer_max_3_4',`tax_mean_3_4',`tax_min_3_4',`tax_max_3_4',`inc5_mean_3_5',`inc5_min_3_5',`inc5_max_3_5',`transfer_mean_3_5',`transfer_min_3_5',`transfer_max_3_5',`tax_mean_3_5',`tax_min_3_5',`tax_max_3_5',`inc6_mean_3_6',`inc6_min_3_6',`inc6_max_3_6',`transfer_mean_3_6',`transfer_min_3_6',`transfer_max_3_6',`tax_mean_3_6',`tax_min_3_6',`tax_max_3_6'"    
	 di "`ccyy',D04,`inc1_mean_4_1',`inc1_min_4_1',`inc1_max_4_1',`transfer_mean_4_1',`transfer_min_4_1',`transfer_max_4_1',`tax_mean_4_1',`tax_min_4_1',`tax_max_4_1',`inc2_mean_4_2',`inc2_min_4_2',`inc2_max_4_2',`transfer_mean_4_2',`transfer_min_4_2',`transfer_max_4_2',`tax_mean_4_2',`tax_min_4_2',`tax_max_4_2',`inc3_mean_4_3',`inc3_min_4_3',`inc3_max_4_3',`transfer_mean_4_3',`transfer_min_4_3',`transfer_max_4_3',`tax_mean_4_3',`tax_min_4_3',`tax_max_4_3',`inc4_mean_4_4',`inc4_min_4_4',`inc4_max_4_4',`transfer_mean_4_4',`transfer_min_4_4',`transfer_max_4_4',`tax_mean_4_4',`tax_min_4_4',`tax_max_4_4',`inc5_mean_4_5',`inc5_min_4_5',`inc5_max_4_5',`transfer_mean_4_5',`transfer_min_4_5',`transfer_max_4_5',`tax_mean_4_5',`tax_min_4_5',`tax_max_4_5',`inc6_mean_4_6',`inc6_min_4_6',`inc6_max_4_6',`transfer_mean_4_6',`transfer_min_4_6',`transfer_max_4_6',`tax_mean_4_6',`tax_min_4_6',`tax_max_4_6'"
     di "`ccyy',D05,`inc1_mean_5_1',`inc1_min_5_1',`inc1_max_5_1',`transfer_mean_5_1',`transfer_min_5_1',`transfer_max_5_1',`tax_mean_5_1',`tax_min_5_1',`tax_max_5_1',`inc2_mean_5_2',`inc2_min_5_2',`inc2_max_5_2',`transfer_mean_5_2',`transfer_min_5_2',`transfer_max_5_2',`tax_mean_5_2',`tax_min_5_2',`tax_max_5_2',`inc3_mean_5_3',`inc3_min_5_3',`inc3_max_5_3',`transfer_mean_5_3',`transfer_min_5_3',`transfer_max_5_3',`tax_mean_5_3',`tax_min_5_3',`tax_max_5_3',`inc4_mean_5_4',`inc4_min_5_4',`inc4_max_5_4',`transfer_mean_5_4',`transfer_min_5_4',`transfer_max_5_4',`tax_mean_5_4',`tax_min_5_4',`tax_max_5_4',`inc5_mean_5_5',`inc5_min_5_5',`inc5_max_5_5',`transfer_mean_5_5',`transfer_min_5_5',`transfer_max_5_5',`tax_mean_5_5',`tax_min_5_5',`tax_max_5_5',`inc6_mean_5_6',`inc6_min_5_6',`inc6_max_5_6',`transfer_mean_5_6',`transfer_min_5_6',`transfer_max_5_6',`tax_mean_5_6',`tax_min_5_6',`tax_max_5_6'"
     di "`ccyy',D06,`inc1_mean_6_1',`inc1_min_6_1',`inc1_max_6_1',`transfer_mean_6_1',`transfer_min_6_1',`transfer_max_6_1',`tax_mean_6_1',`tax_min_6_1',`tax_max_6_1',`inc2_mean_6_2',`inc2_min_6_2',`inc2_max_6_2',`transfer_mean_6_2',`transfer_min_6_2',`transfer_max_6_2',`tax_mean_6_2',`tax_min_6_2',`tax_max_6_2',`inc3_mean_6_3',`inc3_min_6_3',`inc3_max_6_3',`transfer_mean_6_3',`transfer_min_6_3',`transfer_max_6_3',`tax_mean_6_3',`tax_min_6_3',`tax_max_6_3',`inc4_mean_6_4',`inc4_min_6_4',`inc4_max_6_4',`transfer_mean_6_4',`transfer_min_6_4',`transfer_max_6_4',`tax_mean_6_4',`tax_min_6_4',`tax_max_6_4',`inc5_mean_6_5',`inc5_min_6_5',`inc5_max_6_5',`transfer_mean_6_5',`transfer_min_6_5',`transfer_max_6_5',`tax_mean_6_5',`tax_min_6_5',`tax_max_6_5',`inc6_mean_6_6',`inc6_min_6_6',`inc6_max_6_6',`transfer_mean_6_6',`transfer_min_6_6',`transfer_max_6_6',`tax_mean_6_6',`tax_min_6_6',`tax_max_6_6'"
     di "`ccyy',D07,`inc1_mean_7_1',`inc1_min_7_1',`inc1_max_7_1',`transfer_mean_7_1',`transfer_min_7_1',`transfer_max_7_1',`tax_mean_7_1',`tax_min_7_1',`tax_max_7_1',`inc2_mean_7_2',`inc2_min_7_2',`inc2_max_7_2',`transfer_mean_7_2',`transfer_min_7_2',`transfer_max_7_2',`tax_mean_7_2',`tax_min_7_2',`tax_max_7_2',`inc3_mean_7_3',`inc3_min_7_3',`inc3_max_7_3',`transfer_mean_7_3',`transfer_min_7_3',`transfer_max_7_3',`tax_mean_7_3',`tax_min_7_3',`tax_max_7_3',`inc4_mean_7_4',`inc4_min_7_4',`inc4_max_7_4',`transfer_mean_7_4',`transfer_min_7_4',`transfer_max_7_4',`tax_mean_7_4',`tax_min_7_4',`tax_max_7_4',`inc5_mean_7_5',`inc5_min_7_5',`inc5_max_7_5',`transfer_mean_7_5',`transfer_min_7_5',`transfer_max_7_5',`tax_mean_7_5',`tax_min_7_5',`tax_max_7_5',`inc6_mean_7_6',`inc6_min_7_6',`inc6_max_7_6',`transfer_mean_7_6',`transfer_min_7_6',`transfer_max_7_6',`tax_mean_7_6',`tax_min_7_6',`tax_max_7_6'"
     di "`ccyy',D08,`inc1_mean_8_1',`inc1_min_8_1',`inc1_max_8_1',`transfer_mean_8_1',`transfer_min_8_1',`transfer_max_8_1',`tax_mean_8_1',`tax_min_8_1',`tax_max_8_1',`inc2_mean_8_2',`inc2_min_8_2',`inc2_max_8_2',`transfer_mean_8_2',`transfer_min_8_2',`transfer_max_8_2',`tax_mean_8_2',`tax_min_8_2',`tax_max_8_2',`inc3_mean_8_3',`inc3_min_8_3',`inc3_max_8_3',`transfer_mean_8_3',`transfer_min_8_3',`transfer_max_8_3',`tax_mean_8_3',`tax_min_8_3',`tax_max_8_3',`inc4_mean_8_4',`inc4_min_8_4',`inc4_max_8_4',`transfer_mean_8_4',`transfer_min_8_4',`transfer_max_8_4',`tax_mean_8_4',`tax_min_8_4',`tax_max_8_4',`inc5_mean_8_5',`inc5_min_8_5',`inc5_max_8_5',`transfer_mean_8_5',`transfer_min_8_5',`transfer_max_8_5',`tax_mean_8_5',`tax_min_8_5',`tax_max_8_5',`inc6_mean_8_6',`inc6_min_8_6',`inc6_max_8_6',`transfer_mean_8_6',`transfer_min_8_6',`transfer_max_8_6',`tax_mean_8_6',`tax_min_8_6',`tax_max_8_6'"
     di "`ccyy',D09,`inc1_mean_9_1',`inc1_min_9_1',`inc1_max_9_1',`transfer_mean_9_1',`transfer_min_9_1',`transfer_max_9_1',`tax_mean_9_1',`tax_min_9_1',`tax_max_9_1',`inc2_mean_9_2',`inc2_min_9_2',`inc2_max_9_2',`transfer_mean_9_2',`transfer_min_9_2',`transfer_max_9_2',`tax_mean_9_2',`tax_min_9_2',`tax_max_9_2',`inc3_mean_9_3',`inc3_min_9_3',`inc3_max_9_3',`transfer_mean_9_3',`transfer_min_9_3',`transfer_max_9_3',`tax_mean_9_3',`tax_min_9_3',`tax_max_9_3',`inc4_mean_9_4',`inc4_min_9_4',`inc4_max_9_4',`transfer_mean_9_4',`transfer_min_9_4',`transfer_max_9_4',`tax_mean_9_4',`tax_min_9_4',`tax_max_9_4',`inc5_mean_9_5',`inc5_min_9_5',`inc5_max_9_5',`transfer_mean_9_5',`transfer_min_9_5',`transfer_max_9_5',`tax_mean_9_5',`tax_min_9_5',`tax_max_9_5',`inc6_mean_9_6',`inc6_min_9_6',`inc6_max_9_6',`transfer_mean_9_6',`transfer_min_9_6',`transfer_max_9_6',`tax_mean_9_6',`tax_min_9_6',`tax_max_9_6'"
	 di "`ccyy',D10,`inc1_mean_10_1',`inc1_min_10_1',`inc1_max_10_1',`transfer_mean_10_1',`transfer_min_10_1',`transfer_max_10_1',`tax_mean_10_1',`tax_min_10_1',`tax_max_10_1',`inc2_mean_10_2',`inc2_min_10_2',`inc2_max_10_2',`transfer_mean_10_2',`transfer_min_10_2',`transfer_max_10_2',`tax_mean_10_2',`tax_min_10_2',`tax_max_10_2',`inc3_mean_10_3',`inc3_min_10_3',`inc3_max_10_3',`transfer_mean_10_3',`transfer_min_10_3',`transfer_max_10_3',`tax_mean_10_3',`tax_min_10_3',`tax_max_10_3',`inc4_mean_10_4',`inc4_min_10_4',`inc4_max_10_4',`transfer_mean_10_4',`transfer_min_10_4',`transfer_max_10_4',`tax_mean_10_4',`tax_min_10_4',`tax_max_10_4',`inc5_mean_10_5',`inc5_min_10_5',`inc5_max_10_5',`transfer_mean_10_5',`transfer_min_10_5',`transfer_max_10_5',`tax_mean_10_5',`tax_min_10_5',`tax_max_10_5',`inc6_mean_10_6',`inc6_min_10_6',`inc6_max_10_6',`transfer_mean_10_6',`transfer_min_10_6',`transfer_max_10_6',`tax_mean_10_6',`tax_min_10_6',`tax_max_10_6'"
	 if "`ccyy'" == "at04"  di "Inequality Measures 1,countryyear,inc1_gini,inc2_gini,inc3_gini,inc4_gini, inc5_gini, inc6_gini, dhi_gini,transfer_conc_inc1,transfer_conc_inc2,transfer_conc_inc3,transfer_conc_inc4,transfer_conc_inc5, transfer_conc_inc6,tax_conc_inc1,tax_conc_inc2,tax_conc_inc3,tax_conc_inc4, tax_conc_inc5, tax_conc_inc6"
     di "Inequality Measures 1,`ccyy',`inc1_gini',`inc2_gini',`inc3_gini',`inc4_gini',`inc5_gini',`inc6_gini',`dhi_gini',`transferconc_inc1',`transferconc_inc2',`transferconc_inc3',`transferconc_inc4',`transferconc_inc5',`transferconc_inc6',`taxconc_inc1',`taxconc_inc2',`taxconc_inc3',`taxconc_inc4', `taxconc_inc5', `taxconc_inc6'"
	 if "`ccyy'" == "at04"  di "Inequality Measures 2,countryyear,allpension_conc_inc1,allpension_conc_inc2,allpension_conc_inc3,allpension_conc_inc4, allpension_conc_inc5, allpension_conc_inc6,pubpension_conc_inc1,pubpension_conc_inc2,pubpension_conc_inc3,pubpension_conc_inc4,pubpension_conc_inc5, pubpension_conc_inc6, pripension_conc_inc1, pripension_conc_inc2,pripension_conc_inc3,pripension_conc_inc4, pripension_conc_inc5, pripension_conc_inc6"
     di "Inequality Measures 2,`ccyy',`allpensionconc_inc1',`allpensionconc_inc2',`allpensionconc_inc3',`allpensionconc_inc4', `allpensionconc_inc5', `allpensionconc_inc6', `pubpensionconc_inc1',`pubpensionconc_inc2',`pubpensionconc_inc3',`pubpensionconc_inc4',`pubpensionconc_inc5', `pubpensionconc_inc6',`pripensionconc_inc1',`pripensionconc_inc2',`pripensionconc_inc3',`pripensionconc_inc4', `pripensionconc_inc5', `pripensionconc_inc6'"
	 if "`ccyy'" == "at04"  di "Inequality Measures 3,countryyear,inc1_mean,inc2_mean,inc3_mean,inc4_mean,inc5_mean, inc6_mean, dhi_mean,transfer_mean,tax_mean,allpension_mean,pubpension_mean,pripension_mean"
     di "Inequality Measures 3,`ccyy',`inc1_mean',`inc2_mean',`inc3_mean',`inc4_mean',`inc5_mean',`inc6_mean',`dhi_mean',`transfer_mean',`tax_mean',`allpension_mean',`pubpension_mean',`pripension_mean'"
	 if "`ccyy'" == "at04"  di "Inequality Measures 4,countryyear,inc1_conc_inc1,inc2_conc_inc2,inc3_conc_inc3,inc4_conc_inc4,inc5_conc_inc5,inc6_conc_inc6"
     di "Inequality Measures 4,`ccyy',`inc1conc_inc1',`inc2conc_inc2',`inc3conc_inc3',`inc4conc_inc4',`inc5conc_inc5',`inc6conc_inc6'"
	 if "`ccyy'" == "at04"  di "Inequality Measures 5,countryyear,hxits_mean,hsscee_mean,hsscer_mean,hssc_mean,hxitsconc_inc3,hssceeconc_inc3,hsscerconc_inc3,hsscconc_inc3"
     di "Inequality Measures 5,`ccyy',`hxits_mean',`hsscee_mean',`hsscer_mean',`hssc_mean',`hxitsconc_inc3',`hssceeconc_inc3',`hsscerconc_inc3',`hsscconc_inc3'"
	 if "`ccyy'" == "at04"  di "Inequality Measures 6,countryyear,hhaa_inc1_gini,hhaa_inc2_gini,hhaa_inc3_gini,hhaa_inc4_gini,hhaa_inc5_gini,hhaa_inc6_gini,hhaa_dhi_gini,hhaa_transfer_conc_inc1,hhaa_transfer_conc_inc2,hhaa_transfer_conc_inc3,hhaa_transfer_conc_inc4,hhaa_transfer_conc_inc5,hhaa_transfer_conc_inc6,hhaa_tax_conc_inc1,hhaa_tax_conc_inc2,hhaa_tax_conc_inc3,hhaa_tax_conc_inc4,hhaa_tax_conc_inc5, hhaa_tax_conc_inc6"
	 di "Inequality Measures 6,`ccyy',`hhaa_inc1_gini',`hhaa_inc2_gini',`hhaa_inc3_gini',`hhaa_inc4_gini', `hhaa_inc5_gini', `hhaa_inc6_gini',`hhaa_dhi_gini',`hhaa_transferconc_inc1',`hhaa_transferconc_inc2', `hhaa_transferconc_inc3', `hhaa_transferconc_inc4', `hhaa_transferconc_inc5', `hhaa_transferconc_inc6',`hhaa_taxconc_inc1',`hhaa_taxconc_inc2',`hhaa_taxconc_inc3',`hhaa_taxconc_inc4', `hhaa_taxconc_inc5', `hhaa_taxconc_inc6'"
	 if "`ccyy'" == "at04"  di "Inequality Measures 7,countryyear,hhaa_inc1_mean,hhaa_inc2_mean,hhaa_inc3_mean,hhaa_inc4_mean, hhaa_inc5_mean, hhaa_inc6_mean,hhaa_dhi_mean,hhaa_transfer_mean,hhaa_tax_mean,hhaa_allpension_mean,hhaa_pubpension_mean,hhaa_pripension_mean"
     di "Inequality Measures 7,`ccyy',`hhaa_inc1_mean',`hhaa_inc2_mean',`hhaa_inc3_mean',`hhaa_inc4_mean', `hhaa_inc5_mean', `hhaa_inc6_mean',`hhaa_dhi_mean',`hhaa_transfer_mean',`hhaa_tax_mean',`hhaa_allpension_mean',`hhaa_pubpension_mean',`hhaa_pripension_mean'"
 }

program drop _all
clear all
