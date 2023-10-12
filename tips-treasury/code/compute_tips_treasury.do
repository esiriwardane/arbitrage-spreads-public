/*
Create constant-maturity TIPS-Treasury arbitrage series
*/

adopath + "input/lib/stata"
standardize_env 
est drop _all

* ------------------------------------------------------------------------------
* Import inflation swap data 
* ------------------------------------------------------------------------------

import excel "input/treasury_inflation_swaps.xlsx", ///
	sheet("Data") cellrange(C6) firstrow clear
rename (H K L M N) (inf_swap_2y inf_swap_5y inf_swap_10y inf_swap_20y inf_swap_30y)

foreach v in inf_swap_2y inf_swap_5y inf_swap_10y inf_swap_20y inf_swap_30y {
	destring `v', force replace
	replace `v' = `v' / 100
}
rename Dates date
keep date inf*

tempfile swaps
save `swaps'


* ------------------------------------------------------------------------------
* Read in zero-coupon TIPS and Treasury yields
* ------------------------------------------------------------------------------

*Nominal
import delimited "input/feds200628.csv", varnames(10) rowrange(11:16143) clear
gen d = date(date, "MDY", 2023)
format d %td
drop date
rename d date

foreach t in 2 5 10 20 {
	if `t' < 10 local v sveny0`t'
	else local v sveny`t'
	
	destring `v', force replace
	gen nom_zc`t' = 1e4*(exp(`v'/100) - 1) 			// Put in basis points
}

keep date nom*
tempfile nom
save `nom'

*TIPS
import delimited "input/feds200805.csv", varnames(19) rowrange(20:6354) clear
gen d = date(date, "YMD")
format d %td
drop date
rename d date

foreach t in 2 5 10 20 {
	if `t' < 10 local v tipsy0`t'
	else local v tipsy`t'
	
	destring `v', force replace
	gen real_cc`t' = `v' / 100
}

keep date real*
tempfile real
save `real'

* ------------------------------------------------------------------------------
* Merge all data, compute implied riskless rate from TIPS
* ------------------------------------------------------------------------------

use `real', clear
merge 1:1 date using `nom', keep(3) nogen
merge 1:1 date using `swaps', keep(3) nogen

foreach t in 2 5 10 20 {
	gen tips_treas_`t'_rf = 1e4 * (exp(real_cc`t' + log(1 + inf_swap_`t'y)) - 1)
	gen mi_`t' = mi(tips_treas_`t'_rf)
	gen arb`t' = tips_treas_`t'_rf - nom_zc`t'
}

*Drop if missing all series
egen miss_count = rowtotal(mi*)
drop if miss_count == 4
drop mi*

*Save
keep date real_* nom_* tips_*
compress 
save "output/tips_treasury_implied_rf.dta", replace
