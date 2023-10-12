/*
Compute CIP implied riskless rates
*/

adopath + "input/lib/stata"
standardize_env 
est drop _all


*Merge all data
use "temp/RF_Master_File", clear

joinby Date using "temp/Fut_Master_File", unmatched(both)
drop _merge

joinby Date using "temp/Spot_FX_Master", unmatched(both)
drop _merge


******** 
foreach i in AUD CAD CHF DKK EUR GBP JPY NOK NZD SEK{
rename Fut_`i' Fut_`i'_USD
rename Spot_`i' Spot_`i'_USD
}


**** Compute the CIP basis 
foreach i in AUD CAD CHF DKK EUR GBP JPY NOK NZD SEK{
gen cip_`i'_USD_ln= 100*100 * ((RF_`i'/100 - (360/90)*(log(Fut_`i'_USD)-log(Spot_`i'_USD) )) - RF_USD/100) // in basis points 
gen cip_`i'_USD= 100*100 * ((RF_`i'/100 - (360/90)*(Fut_`i'_USD/Spot_`i'_USD - 1) ) - RF_USD/100) // in basis points 
}

**** The correlations and betas of logs on levels is near 1
foreach i in AUD CAD CHF DKK EUR GBP JPY NOK NZD SEK{
	reg cip_`i'_USD_ln cip_`i'_USD, r
}

keep Date cip_AUD_USD-cip_SEK_USD RF_USD

*Outlier cleanup following Barndorff-Nielsen et al. (2009)
sort Date
foreach c in GBP EUR JPY AUD CAD CHF DKK NZD SEK NOK {
	
	rangestat (median) cip_`c'_USD, interval(Date -45 45) excludeself
	gen abs_dev = abs(cip_`c'_USD - cip_`c'_USD_median)
	rangestat (mean) mad=abs_dev, interval(Date -45 45) excludeself
	gen bad_price = (abs_dev/mad) >= 10
	replace bad_price = . if mi(cip_`c'_USD)
	replace cip_`c'_USD = . if bad_price==1  & !missing(bad_price)  	
	drop cip_`c'_USD_median abs_dev bad_price mad
}

		
*Add back USD OIS to get implied riskless rates
foreach i in AUD CAD CHF DKK EUR GBP JPY NOK NZD SEK{
gen cip_`i'_rf = cip_`i'_USD + 100*RF_USD
}

keep Date *_rf

label var cip_AUD_rf "3M GBP Synthetic Dollar OIS"
label var cip_CAD_rf "3M CAD Synthetic Dollar OIS"
label var cip_CHF_rf "3M CHF Synthetic Dollar OIS"
label var cip_DKK_rf "3M DKK Synthetic Dollar LIBOR"
label var cip_EUR_rf "3M EUR Synthetic Dollar OIS"
label var cip_GBP_rf "3M GBP Synthetic Dollar OIS"
label var cip_JPY_rf "3M JPY Synthetic Dollar OIS"
label var cip_NOK_rf "3M NOK Synthetic Dollar LIBOR"
label var cip_NZD_rf "3M NZD Synthetic Dollar OIS"
label var cip_SEK_rf "3M SEK Synthetic Dollar OIS"

/*Note: OIS rates in DKK and NOK do not exist. Du, Tepper, and Verdelhan, 2018
		use LIBOR for these (and all) currencies in their baseline analysis.
		We prefer OIS so we drop both. Users can uncomment below to keep these, 
		but should note that the synthetic dollar rate is then comparable to 
		LIBOR.
*/ 
drop cip_DKK_rf cip_NOK_rf
rename *, lower
save "output/cip_implied_rf.dta", replace














