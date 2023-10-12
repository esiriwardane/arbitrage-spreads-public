/*
Compute Treasury Swap Spread
*/

adopath + "input/lib/stata"
standardize_env 
est drop _all

**** OIS Swaps
import excel "input/treasury_swap.xlsx", sheet("Interest Rate Swaps") ///
cellrange(A6) firstrow clear
rename (PX_LAST C D E F G H) (USSO1CMPNCurncy USSO2CMPNCurncy ///
USSO3CMPNCurncy USSO5CMPNCurncy USSO10CMPNCurncy ///
USSO20CMPNCurncy USSO30CMPNCurncy)

foreach v in USSO1CMPNCurncy USSO2CMPNCurncy ///
USSO3CMPNCurncy USSO5CMPNCurncy USSO10CMPNCurncy ///
USSO20CMPNCurncy USSO30CMPNCurncy{
destring `v', replace force
}
rename Dates Date
save "input/I_Swap", replace

**** Treasury Yields 
import excel "input/treasury_swap.xlsx", sheet("Treasury Yields") ///
cellrange(A6) firstrow clear
rename (PX_LAST C D E F G H I J K L M) ( M1 M2 M3 M6 Y1 Y2 Y3 Y5 Y7 Y10 Y20 Y30)

foreach v in M1 M2 M3 M6 Y1 Y2 Y3 Y5 Y7 Y10 Y20 Y30{
destring `v', replace force
}
rename Dates Date
save "input/T_Yield", replace

**** Merger 
use  "input/I_Swap", clear
joinby Date using "input/T_Yield", unmatched(both)
keep if _merge == 3
drop _merge 

***** Compute arbitrage   Treasury Yield -Swap Yield 
foreach v in 1 2 3 5 10 20 30{
gen Arb_Swap_`v' = (Y`v'-USSO`v'CMPNCurncy ) *100
}

**** Swap RF rate (put in basis points and rename)
foreach v in 1 2 3 5 10 20 30{
	rename USSO`v'CMPNCurncy Swap_RF_`v'
	replace Swap_RF_`v' = Swap_RF_`v' * 100
}

**** Keep data post 2000
keep if year(Date) >= 2000 

**** Drop if missing all swap obs
gen Missing_All = 1
foreach v in Arb_Swap_1 Arb_Swap_2 Arb_Swap_3 Arb_Swap_5 Arb_Swap_10 Arb_Swap_20 ///
Arb_Swap_30{
	replace Missing_All = 0 if !missing(`v') 
}
drop if Missing_All == 1 

keep Date Arb_Swap_1 Arb_Swap_2 Arb_Swap_3 Arb_Swap_5 Arb_Swap_10 Arb_Swap_20 ///
Arb_Swap_30 Swap_RF_1-Swap_RF_30

*Clean up names
rename (Swap_RF_1 Swap_RF_2 Swap_RF_3 Swap_RF_5 Swap_RF_10 Swap_RF_20 Swap_RF_30) ///
  (tswap_1_rf tswap_2_rf tswap_3_rf tswap_5_rf tswap_10_rf tswap_20_rf tswap_30_rf)
label var tswap_1_rf "Treasury-Swap 1Y Implied Rf"
label var tswap_2_rf "Treasury-Swap 2Y Implied Rf"
label var tswap_3_rf "Treasury-Swap 3Y Implied Rf"
label var tswap_5_rf "Treasury-Swap 5Y Implied Rf"
label var tswap_10_rf "Treasury-Swap 10Y Implied RF"
label var tswap_20_rf "Treasury-Swap 20Y Implied RF"
label var tswap_30_rf "Treasury-Swap 30Y Implied RF"
rename *, lower

keep tswap* date

save "output/tswap_implied_rf.dta", replace
