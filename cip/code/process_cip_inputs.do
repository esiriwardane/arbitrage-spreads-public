adopath + "input/lib/stata"
standardize_env 
est drop _all

*Define files for future prices, dividends, and maturity information


**********************
**** Process Riskless rate data
/*
Notes on what we use for riskless rates:
	- When possible, we use local-currency OIS rates
	- CHF transitioned from TOIS fixing to SARON fixing on Jan 1, 2018. 
	  SARON is the overnight secured borrowing rate in CHF and is akin to SOFR 
	  in the US. We therefore use SARON for CHF after 2017.
	  (source: https://tinyurl.com/2ev6j59j)
	- The EUR transitioned from EONIA to EST fixing as of Jan 3, 2022. EST 
	  is based on overnight secured borrowing rates and is akin to U.S. SOFR.
	  (source: https://tinyurl.com/4adhxuts)
	- OIS rates are not available for DKK and NOK. We use LIBOR for these 
	  two currencies, so the synthetic dollar rate should be compared to USD 
	  LIBOR.
*/

import excel "input/cip.xlsx", sheet("OIS") cellrange(F6) firstrow clear
rename (Dates PX_LAST H I J K L M N O P Q R S) ///
(Date AUD CAD  CHF_Secured CHF DKK EUR_Secured EUR GBP JPY NOK NZD SEK USD )

foreach v in AUD CAD CHF_Secured CHF DKK EUR_Secured EUR GBP JPY NOK NZD SEK USD{
	destring `v', replace force 
	rename `v' RF_`v'
}

replace RF_CHF=RF_CHF_Secured if year(Date)>=2018 
replace RF_EUR=RF_EUR_Secured if year(Date)>=2022 
drop RF_CHF_Secured RF_EUR_Secured

drop if missing(Date)
save "temp/RF_Master_File", replace



********************************************************************************************************************************************
*** Process Spot Data
import excel "input/cip.xlsx", sheet("Spot") cellrange(C6) firstrow clear
rename (Dates PX_LAST E F G H I J K L M) (Date AUD CAD CHF DKK EUR GBP JPY NOK NZD SEK)

foreach v in AUD CAD CHF DKK EUR GBP JPY NOK NZD SEK{
rename `v' Spot_`v'
destring  Spot_`v', replace force 
}

destring Spot_EUR, replace force

*** Convert all into Local/USD
replace Spot_GBP=1/Spot_GBP
replace Spot_EUR=1/Spot_EUR
replace Spot_AUD=1/Spot_AUD
replace Spot_NZD=1/Spot_NZD

 
drop if missing(Date)
save "temp/Spot_FX_Master", replace
***


********************************************************************************************************************************************
*** Process Forwards Data
import excel "input/cip.xlsx", sheet("Forward") cellrange(C6) firstrow clear
rename (Dates PX_LAST E F G H I J K L M) (Date AUD CAD CHF DKK EUR GBP JPY NOK NZD SEK)

foreach v in AUD CAD CHF DKK EUR GBP JPY NOK NZD SEK{
rename `v' Fut_`v'
destring  Fut_`v', replace force 
}


***********************************
**********Convert from Fut basis to Fut exchange rate
***********************************
joinby Date using "temp/Spot_FX_Master",unmatched(both)
keep if _merge==3
drop _merge

*** uncorrect spot to match the fut into Local/USD
gen F_Spot_GBP=1/Spot_GBP
gen F_Spot_EUR=1/Spot_EUR
gen F_Spot_AUD=1/Spot_AUD
gen F_Spot_NZD=1/Spot_NZD

foreach C in CAD CHF DKK  NOK SEK{
rename Fut_`C' Fut_`C'_Basis
gen Fut_`C'=Spot_`C'+Fut_`C'_Basis/10000
}
*** JPY basis is scaled by 100, not 10,000
rename Fut_JPY Fut_JPY_Basis
gen Fut_JPY=Spot_JPY+Fut_JPY_Basis/100

foreach C in AUD EUR GBP NZD {
rename Fut_`C' Fut_`C'_Basis
gen Fut_`C'=F_Spot_`C'+Fut_`C'_Basis/10000
}

*** Convert all into Local/USD
replace Fut_GBP=1/Fut_GBP
replace Fut_EUR=1/Fut_EUR
replace Fut_AUD=1/Fut_AUD
replace Fut_NZD=1/Fut_NZD

keep Date Fut_CAD-Fut_NZD
aorder
order Date, first

save "temp/Fut_Master_File", replace





