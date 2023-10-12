/*
Compute implied riskless rates from equity futures
*/
adopath + "input/lib/stata"
standardize_env 
est drop _all

*Cycle through futures data and assemble implied riskless rates
clear
tempfile results
save `results', emptyok

local i 1
foreach v in SP DowJones Nasdaq {
	
	*Load data
	use "temp/`v'_futures.dta", clear
	merge m:1 date using "input/USD_OIS_Rates.dta", keep(3) nogen
	sort date
	
	*Set names
	if "`v'" == "SP" local vname spx
	else if "`v'" == "DowJones" local vname dow
	else if "`v'" == "Nasdaq" local vname ndaq
	
	*Maturity-matched OIS rates (linear interpolation)
	gen TTM = Mat-date
	gen OIS = OIS_1W if TTM <= 7
	replace OIS = ((30-TTM)/23)*OIS_1W + ((TTM-7)/23)*OIS_1M if TTM>7 & TTM<=30
	replace OIS = ((90-TTM)/60)*OIS_1M + ((TTM-30)/60)*OIS_3M if TTM>30 & TTM<=90
	replace OIS = ((180-TTM)/90)*OIS_3M + ((TTM-90)/90)*OIS_6M if TTM>90 & TTM<=180
	replace OIS = ((360-TTM)/180)*OIS_6M + ((TTM-180)/180)*OIS_1Y if TTM>180
	drop OIS_*
	replace OIS = OIS / 100

	*Reshape
	drop if missing(Term)
	keep Mat F_P Div_Sum TTM OIS Spot_Price date Term
	reshape wide Mat F_P Div_Sum TTM OIS Spot_Price, i(date) j(Term)
	rename Spot_Price1 `vname'_Spot
	drop if missing(`vname'_Spot)
	drop Spot_Price2
	
	*Implied forward rates (annualized)
	*Compound dividends at OIS rate assuming that they are paid uniformly 
	gen Div_Sum2_Comp=Div_Sum2*((TTM2/2)/360*OIS2+1) 
	gen Div_Sum1_Comp=Div_Sum1*((TTM1/2)/360*OIS1+1)

	gen implied_forward_raw = ((F_P2 + Div_Sum2_Comp) / (F_P1 + Div_Sum1_Comp) - 1)
	gen cal_`vname'_rf = 100 * implied_forward_raw * (360 / (TTM2-TTM1))
	
	*Generate OIS-implied forward rates
	gen ois_fwd_raw = (1 + OIS2 * TTM2 / 360) / (1 + OIS1 * TTM1 / 360) - 1
	gen ois_fwd_`vname' = 100 * ois_fwd_raw * 360 / (TTM2 - TTM1) 
	drop ois_fwd_raw implied_forward_raw
	
	*Plot raw implied riskless rate
	twoway line cal_`vname'_rf date, ///
		ytitle("Implied Rf (%)") title("`vname'")
	graph export "output/`v'_implied_rf.pdf", as(pdf) replace		
	
	*Outlier cleanup following Barndorff-Nielsen et al. (2009)
	sort date
	gen arb_`vname' = cal_`vname'_rf - ois_fwd_`vname' 
	rangestat (median) arb_`vname', interval(date -45 45) excludeself
	gen abs_dev = abs(arb_`vname' - arb_`vname'_median)
	rangestat (mean) mad=abs_dev, interval(date -45 45) excludeself
	gen bad_price = (abs_dev/mad) >= 10
	replace bad_price = . if mi(arb_`vname')
	replace cal_`vname'_rf  = . if bad_price == 1 & ~mi(bad_price)
	
	*Rescale to basis points
	replace cal_`vname'_rf = cal_`vname'_rf * 100
	replace ois_fwd_`vname' = ois_fwd_`vname' * 100 
	
	* Append all results and save OIS-implied forwards
	keep date cal_`vname'_rf ois_fwd_`vname'
	if `i' > 1 merge 1:1 date using `results', nogen
	save `results', replace
	local ++i
}

*Cleanup OIS rates (named so it is clear these are forward rates)
egen ois_fwd_cal = rowmean(ois_fwd_spx ois_fwd_dow ois_fwd_ndaq)
drop ois_fwd_spx ois_fwd_dow ois_fwd_ndaq

/*The Dow Jones has clear errors very early in the same (implied RFs over 12%), 
so we include from 2003 onwards. See output plots for details.
*/

keep if yofd(date) >= 2003
sort date

*Label and output
label var cal_spx_rf "SPX Equity-SF Implied Rf"
label var cal_dow_rf "DJX Equity-SF Implied Rf"
label var cal_ndaq_rf "NDAQ Equity-SF Implied Rf"
label var ois_fwd_cal "Forward OIS Rate for Calendar Spread"

rename *, lower
compress
save "output/equity_sf_implied_rf.dta", replace

*Plot all together
twoway line cal* date, ytitle("Implied RF (%)") ///
	note("Excludes outliers and pre-2003 data")
graph export "output/all_implied_rf.pdf", as(pdf) replace
