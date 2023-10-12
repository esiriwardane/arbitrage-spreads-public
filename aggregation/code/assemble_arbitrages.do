/*
Assemble sample of arbitrage-implied riskless rates and spreads over benchmarks
	1. Merge all implied riskless rates together
	2. Reshape into panel format
	3. Get maturity-matched OIS, LIBOR, and Treasury rates
	4. Construct arbitrage spreads
*/

adopath + "input/lib/stata"
standardize_env 
est drop _all

* ------------------------------------------------------------------------------
* Merge all arbitrage implied riskless rates
* ------------------------------------------------------------------------------

*Get data
use "input/cip_implied_rf", clear
merge 1:1 date using "input/box_spreads", keep(1 3) nogen
merge 1:1 date using "input/cds_bond_implied_rf", keep(1 3) nogen ///
	keepusing(cds_bond_ig_rf cds_bond_hy_rf)
merge 1:1 date using "input/equity_sf_implied_rf", keep(1 3) nogen ///
	keepusing(*_rf)
merge 1:1 date using "input/tips_treasury_implied_rf.dta", keep(1 3) nogen ///
	keepusing(*_rf)
merge 1:1 date using "input/treasury_sf_implied_rf.dta", keep(1 3) nogen ///
	keepusing(*_rf)	
merge 1:1 date using "input/tswap_implied_rf.dta", keep(1 3) nogen 

xtset date

*Get first available date and start sample there
egen avg_spread = rowmean(cip_aud_rf-tswap_30_rf)
egen first_date = min(date) if ~mi(avg_spread)
keep if date >= first_date
drop avg_spread first_date

*Save implied riskless rates
compress
save "output/arbitrage_implied_rf_wide.dta", replace


* ------------------------------------------------------------------------------
* Reshape as panel (long format)
* ------------------------------------------------------------------------------

use "output/arbitrage_implied_rf_wide.dta", replace

*Add stubs for reshaping
quietly describe, varlist
local vars `r(varlist)'
local omit date 
local tgt_vars: list vars - omit

foreach var in `tgt_vars' {
	local new = substr("`var'", 1, strpos("`var'", "_rf") - 1) 
	rename `var' rf_`new'
}

*Reshape
reshape long rf_, i(date) j(full_trade) string

*Rename + define strategies and trades
rename rf_ implied_rf
gen strategy = substr(full_trade, 1, strpos(full_trade, "_") - 1) 
gen trade = substr(full_trade, strpos(full_trade, "_") + 1, .) 

replace strategy = "tips_treas" if strategy == "tips"
gen tenor = substr(trade, strpos(trade, "_") + 1, .) 
replace trade = tenor if strategy == "tips_treas"
drop tenor

replace strategy = "cds_bond" if strategy == "cds"
replace trade = "ig" if trade == "bond_ig"
replace trade = "hy" if trade == "bond_hy" 

egen trade_id = group(full_trade)

*Generate dummy variable for trades that depend more on unsecured funding
gen unsecured = 1 if inlist(strategy, "cip", "box", "cal")
replace unsecured = 0 if ~inlist(strategy, "cip", "box", "cal")

*Cleanup and output
label var implied_rf "Arbitrage-implied riskless rate"
label var full_trade "Complete arbitrage name"
label var strategy "Strategy of arbitrage"
label var trade "Identifying information with strategy"
label var unsecured "Indicates trades that rely more on unsecured funding"

xtset date trade_id
compress
save "output/arbitrage_implied_rf_panel.dta", replace

* ------------------------------------------------------------------------------
* Maturity-match OIS, LIBOR, Treasury, TED, LIBOR-OIS + define arbitrage spreads
* ------------------------------------------------------------------------------

use "output/arbitrage_implied_rf_panel.dta", replace

/*Notes. For each trade: 
	1. treasury - nearest-maturity Treasury yield (matched-maturity = t)
	2. ois - nearest-maturity OIS (matched-maturity = o)
	3. libor - nearest-maturity LIBOR (matched-maturity = l)
	4. ted - libor(l) - treasury(l)
	5  libor-ois = libor(l) - ois(l)
	6. arb_ref_rate = ois for all trades with tenor less than 2 years. Use	
						treasury for all other trades
	
	Note that t and o do not necessarily equal l. For example, for the 
	30-year Treasury swap, t = 30 years, o = 24 months, and l = 12 months. This
	means the ted and libor-ois spreads be of tenor l = 12 months
*/

*Merge in Treasury yields, LIBOR, and OIS. For CDS-Bond + TFutures, need
*maturity-matched reference rates. For TIP-Treas, need zero-coupon yields
merge m:1 date using "input/Treasury_Yields.dta", keep(1 3) nogen
merge m:1 date using "input/USD_OIS_Rates.dta", keep(1 3) nogen
merge m:1 date using "input/USD_LIBOR_Rates.dta", keep(1 3) nogen

merge m:1 date using "input/cds_bond_implied_rf.dta", keep(1 3) nogen ///
	keepusing(cds_bond_ig_treas cds_bond_hy_treas)
merge m:1 date using "input/equity_sf_implied_rf.dta", keep(1 3) nogen ///
	keepusing(ois_fwd_cal)	
merge m:1 date using "input/treasury_sf_implied_rf.dta", keep(1 3) nogen ///
	keepusing(tfut_ois* tfut_*ttm*)	
merge m:1 date using "input/tips_treasury_implied_rf.dta", keep(1 3) nogen ///
	keepusing(nom*)
	
*Rescale to basis points
foreach v of varlist tyield_30Y-Libor_1Y {
	replace `v' = `v' * 100
}

xtset date trade_id

*Placeholders for rates
gen treasury_yield = .
gen ois = .
gen libor = .
gen ted = .
gen libor_ois = .
gen arb_ref_rate = .

* -------------------- CIP -------------------- *
replace treasury_yield = tyield_3M if strategy == "cip"
replace ois = OIS_3M if strategy == "cip" 
replace libor = Libor_3M if strategy == "cip"
replace ted = Libor_3M - tyield_3M if strategy == "cip"
replace libor_ois = Libor_3M - OIS_3M if strategy == "cip"
replace arb_ref_rate = ois if strategy == "cip"

* -------------------- Box -------------------- *
*6M
replace treasury_yield = tyield_6M if full_trade == "box_6m"
replace ois = OIS_6M if full_trade == "box_6m"
replace libor = Libor_6M if full_trade == "box_6m"
replace ted = Libor_6M - tyield_6M if full_trade == "box_6m" 
replace libor_ois = Libor_6M - OIS_6M if full_trade == "box_6m"

*12M
replace treasury_yield = tyield_1Y if full_trade == "box_12m"
replace ois = OIS_1Y if full_trade == "box_12m"
replace libor = Libor_1Y if full_trade == "box_12m"
replace ted = Libor_1Y - tyield_1Y if full_trade == "box_12m"
replace libor_ois = Libor_1Y - OIS_1Y if full_trade == "box_12m"

*18M (take average of 1YR and 2YR rates when possible)
replace treasury_yield = (tyield_1Y + tyield_2Y) / 2 if full_trade == "box_18m"
replace ois = (OIS_1Y + OIS_2Y) / 2 if full_trade == "box_18m"
replace libor = Libor_1Y if full_trade == "box_18m"
replace ted = Libor_1Y - tyield_1Y if full_trade == "box_18m"
replace libor_ois = Libor_1Y - OIS_1Y if full_trade == "box_18m"
	
replace arb_ref_rate = ois if strategy == "box"

* -------------------- Calendar spread -------------------- *
pwcorr ois_fwd_cal OIS_3M if full_trade == "cal_spx"

/*Note: Benchmarks for calendar spreads should be forward rates.
We use 3M spot rates to avoid spikes in implied forward rates on roll dates.
This largely does not matter, since the correlation between the implied OIS 
forward rate based on linear interpolation and the spot 3M OIS rate is over 99%
*/
replace treasury_yield = tyield_3M if strategy == "cal"
replace ois = OIS_3M if strategy == "cal"
replace libor = Libor_3M if strategy == "cal"
replace ted = Libor_3M - tyield_3M if strategy == "cal"
replace libor_ois = Libor_3M - OIS_3M if strategy == "cal"
replace arb_ref_rate = ois if strategy == "cal"

* -------------------- Treasury-Swap -------------------- *
*Reference rate should be Treasury yield based on arbitrage execution
foreach m in 1 2 3 5 10 20 30 {
	replace treasury_yield = tyield_`m'Y if full_trade == "tswap_`m'"
	replace ois = OIS_`m'Y if full_trade == "tswap_`m'"
}

replace libor = Libor_1Y if strategy == "tswap"
replace ted = Libor_1Y - tyield_1Y if strategy == "tswap"
replace libor_ois = Libor_1Y - OIS_1Y if strategy == "tswap"
replace arb_ref_rate = treasury_yield if strategy == "tswap" 

* -------------------- Treasury-Futures -------------------- *

replace treasury_yield = (tyield_3M + tyield_6M) / 2 if strategy == "tfut"
replace ois = (OIS_3M + OIS_6M) / 2 if strategy == "tfut"
replace libor = (Libor_3M + Libor_6M) / 2 if strategy == "tfut"
replace ted = libor - treasury_yield if strategy == "tfut"
replace libor_ois = libor - ois if strategy == "tfut"
replace arb_ref_rate = ois if strategy == "tfut"

*Check correlation between linearly interpolated spot rates using exact maturity
*and midpoint of 3M and 6M rate. The latter is useful because it is smooth 
*through rolls

gen treasury_int = .
gen libor_int = .

*Linearly interpolate Treasury and LIBOR.
foreach m in 2 5 10 20 30 {
	
	*Treasuries	- use 1M as left interpolation boundary, since 2M not on FRED
	replace treasury_int = tyield_1M * (90 - tfut_`m'_ttm) / (90 - 30) + ///
		tyield_3M * (tfut_`m'_ttm - 30) / (90 - 30) ///
		if tfut_`m'_ttm > 30 & tfut_`m'_ttm <= 90 & full_trade == "tfut_`m'"
		
	replace treasury_int = tyield_3M * (180 - tfut_`m'_ttm) / (180 - 90) + ///
		tyield_6M * (tfut_`m'_ttm - 90) / (180 - 90) ///
		if tfut_`m'_ttm > 90 & tfut_`m'_ttm <= 180 & full_trade == "tfut_`m'"

	replace treasury_int = tyield_6M * (360 - tfut_`m'_ttm) / (360 - 180) + ///
		tyield_1Y * (tfut_`m'_ttm - 180) / (360 - 180) ///
		if tfut_`m'_ttm > 180 & tfut_`m'_ttm <= 360 & full_trade == "tfut_`m'"				

	*OIS - maturity-matched OIS defined in construction of implied riskless rate
	pwcorr ois tfut_ois_`m' if full_trade == "tfut_`m'"
	
	*LIBOR
	local rf Libor
	replace libor_int = `rf'_2M * (90 - tfut_`m'_ttm) / (90 - 60) + ///
		`rf'_3M * (tfut_`m'_ttm - 60) / (90 - 60) ///
		if tfut_`m'_ttm > 60 & tfut_`m'_ttm <= 90 & full_trade == "tfut_`m'"
		
	replace libor_int = `rf'_3M * (180 - tfut_`m'_ttm) / (180 - 90) + ///
		`rf'_6M * (tfut_`m'_ttm - 90) / (180 - 90) ///
		if tfut_`m'_ttm > 90 & tfut_`m'_ttm <= 180 & full_trade == "tfut_`m'"

	replace libor_int = `rf'_6M * (360 - tfut_`m'_ttm) / (360 - 180) + ///
		`rf'_1Y * (tfut_`m'_ttm - 180) / (360 - 180) ///
		if tfut_`m'_ttm > 180 & tfut_`m'_ttm <= 360 & full_trade == "tfut_`m'"		
}

foreach m in 2 5 10 20 30 {
	pwcorr treasury_yield treasury_int if full_trade == "tfut_`m'"
	pwcorr libor libor_int if full_trade == "tfut_`m'"
	pwcorr ois tfut_ois_`m' if full_trade == "tfut_`m'"		
}
*Correlations are above 99% in all cases. Use midpoint to avoid roll spikes
	

* -------------------- CDS-Bond Basis -------------------- * 
replace treasury_yield = cds_bond_ig_treas if full_trade == "cds_bond_ig"
replace treasury_yield = cds_bond_hy_treas if full_trade == "cds_bond_hy"

replace libor = Libor_1Y if strategy == "cds_bond"
replace ois = OIS_2Y if strategy == "cds_bond"
replace ted = Libor_1Y - tyield_1Y if strategy == "cds_bond"
replace libor_ois = Libor_1Y - OIS_1Y if strategy == "cds_bond"
replace arb_ref_rate = treasury_yield if strategy == "cds_bond"

* -------------------- TIPS-Treasury -------------------- * 

foreach m in 2 5 10 20 {
	replace treasury_yield = nom_zc`m' if full_trade == "tips_treas_`m'"
	replace ois = OIS_`m'Y if full_trade == "tips_treas_`m'"
}
	
replace libor = Libor_1Y if strategy == "tips_treas"
replace ted = Libor_1Y - tyield_1Y if strategy == "tips_treas"
replace libor_ois = Libor_1Y - OIS_1Y if strategy == "tips_treas"
replace arb_ref_rate = treasury_yield if strategy == "tips_treas"

* ------------------------------------------------------------------------------
* Clean up and output as panel format
* ------------------------------------------------------------------------------

*Keep sample based on availability of Fed Funds rates (handles market closures)
drop if mi(fed_funds)

*Drop unnecessary variables
drop tyield* OIS* Libor* cds_bond_ig_treas cds_bond_hy_treas ois_fwd_cal ///
	tfut_ois* tfut_*ttm *_int nom*

*Generate arbitrage spread (bps). Flip sign for CDS-Bond basis
gen raw_arb_spread = implied_rf - arb_ref_rate
replace raw_arb_spread = -raw_arb_spread if strategy == "cds_bond"
gen arb_spread = abs(raw_arb_spread)

*Generate some date variables
gen year = yofd(date)
gen yw = wofd(date)
gen ym = mofd(date)

format yw %tw
format ym %tm

*Clean and save
bysort full_trade (date): gen t = _n
xtset trade_id t

order t date yw ym year trade_id full_trade strategy trade unsecured ///
	implied_rf arb_spread 
	
save "output/arbitrage_spread_panel.dta", replace


* ------------------------------------------------------------------------------
* Create wide format for arbitrage spreads
* ------------------------------------------------------------------------------
use "output/arbitrage_spread_panel.dta", clear

keep date full_trade raw_arb_spread
reshape wide raw_arb_spread, i(date) j(full_trade) string

*Clean up variable names
foreach var of varlist _all {
	local new = subinstr("`var'", "raw_arb_spread", "", .)
	rename `var' `new'
}

*Generate absolute values
foreach v of varlist _all {
	if inlist("`v'", "date") continue
	gen raw_`v' = `v'
	replace `v' = abs(`v')	
}

* --- Label variables --- * 
*CIP
label var cip_gbp "GPB CIP"
label var cip_eur "EUR CIP"
label var cip_jpy "JPY CIP"
label var cip_aud "AUD CIP"
label var cip_cad "CAD CIP"
label var cip_chf "CHF CIP"
label var cip_nzd "NZD CIP"
label var cip_sek "SEK CIP"

*Equity spot futures
label var cal_spx "SPX SF"
label var cal_dow "DJX SF"
label var cal_ndaq "NDAQ SF"

*Box 
label var box_6m "Box 6m"
label var box_12m "Box 12m"
label var box_18m "Box 18m"

*Tips-Treasury
label var tips_treas_2 "TIPS-Treasury 2Y"
label var tips_treas_5 "TIPS-Treasury 5Y"
label var tips_treas_10 "TIPS-Treasury 10Y"
label var tips_treas_20 "TIPS-Treasury 20Y"

*Treasury-Swap
label var tswap_1 "Treasury-Swap 1Y"
label var tswap_2 "Treasury-Swap 2Y"
label var tswap_3 "Treasury-Swap 3Y"
label var tswap_5 "Treasury-Swap 5Y"
label var tswap_10 "Treasury-Swap 10Y"
label var tswap_20 "Treasury-Swap 20Y"
label var tswap_30 "Treasury-Swap 30Y"

*Treasury Spot-Futures
label var tfut_2 "Treasury 2Y SF"
label var tfut_5 "Treasury 5Y SF"
label var tfut_10 "Treasury 10Y SF"
label var tfut_20 "Treasury 20Y SF"
label var tfut_30 "Treasury 30Y SF"

*CDS-Bond
label var cds_bond_ig "CDS-Bond IG"
label var cds_bond_hy "CDS-Bond HY"

*Save
save "output/arbitrage_spread_wide.dta", replace

* ------------------------------------------------------------------------------
* Create dataset of within-strategy means
* ------------------------------------------------------------------------------

use "output/arbitrage_spread_wide.dta", clear

*Collapse CIP arbitrages and keep count of spreads that go into average
unab cip_var: cip*
local num: list sizeof local(cip_var)
egen cip = rowmean(cip*)
gen cip_k = `num'

*Calendar spread
unab cal_var: cal* 
local num : list sizeof local(cal_var)
egen cal_spread = rowmean(cal*)
gen cal_spread_k = `num'

*Box spread
unab box_var: box*
local num : list sizeof local(box_var)
egen box_spread = rowmean(box*)
gen box_spread_k = `num'

*Swap spreads
unab swap_var: tswap* 
local num : list sizeof local(swap_var)
egen tswap = rowmean(tswap*)
gen tswap_k = `num'	
	
*Treasury-Futures basis
unab tfutvar: tfut*
local num : list sizeof local(tfutvar)
egen tfut = rowmean(tfut*)
gen tfut_k = `num'	

*CDS-Bond Basis
unab cdsbond: cds_bond*
local num : list sizeof local(cdsbond)
egen cds_bond = rowmean(cds_bond*)
gen cds_bond_k = `num'	

*TIPS-Treasury
unab tipstreas: tips_treas*
local num : list sizeof local(tipstreas)
egen tips_treas = rowmean(tips_treas*)
gen tips_treas_k = `num'	

*Keep only collapsed spreads
keep date cip cal_spread box_spread tips_treas ///
	tswap tfut cds_bond *_k
order date cip cal_spread box_spread tips_treas ///
	tswap tfut cds_bond *_k
	
*Labels
label var cip "FX CIP"
label var cal_spread "Equity Spot-Fut"
label var box_spread "Equity Box"	
label var tswap "Treasury-Swap"
label var tfut "Treasury Spot-Fut"
label var cds_bond "CDS-Bond"
label var tips_treas "Tips-Treasury"

*Save
save "output/arbitrage_strategy_wide.dta", replace
