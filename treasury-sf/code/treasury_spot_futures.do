/*
Compute implied riskless rates from tresaury spot futures
*/

adopath + "input/lib/stata"
standardize_env 
est drop _all

* Import and reformat data
local data_file "input\treasury_spot_futures.xlsx"
**** Identify the last business day of each month for which the contracts trade 
import excel "`data_file'",  sheet("T_SF") cellrange(A7) clear
keep A
rename A Date
gen Mat_Month = month(Date)
gen Mat_Year = year(Date)
sort Date
keep if mofd(Date)! = mofd(Date[_n+1])
gen Mat_Day = day(Date)
drop Date
drop if _n == _N 
// drop last observation (las month does not have a last business day)
tempfile Mat_Day
save "`Mat_Day'", replace


*** Compute Treasury Spread
import excel using "`data_file'", sheet("T_SF") cellrange(A7) clear

rename (A B C D E F G H I J K L M N O P Q R S T U V W X Y Z AA AB AC AD AE AF AG AH AI AJ AK AL AM AN AO) ///
(Date  Implied_Repo_1_10 Vol_1_10 Contract_1_10 Price_1_10 ///
       Implied_Repo_1_5 Vol_1_5 Contract_1_5 Price_1_5  ///
	   Implied_Repo_1_2 Vol_1_2  Contract_1_2 Price_1_2 ///
       Implied_Repo_1_20 Vol_1_20  Contract_1_20 Price_1_20 ///
	   Implied_Repo_1_30 Vol_1_30 Contract_1_30 Price_1_30 ///
       Implied_Repo_2_10 Vol_2_10 Contract_2_10 Price_2_10 ///
	   Implied_Repo_2_5 Vol_2_5 Contract_2_5 Price_2_5 ///
	   Implied_Repo_2_2 Vol_2_2 Contract_2_2 Price_2_2  ///
       Implied_Repo_2_20 Vol_2_20 Contract_2_20 Price_2_20 ///
	   Implied_Repo_2_30 Vol_2_30 Contract_2_30 Price_2_30 )

drop if mi(Date)
	   
**** destring variables to remove #N/A N/A
foreach v in Implied_Repo* Vol_* Price_*{
	destring `v', replace force 
}
**** rows are date by Treasury_Tenor and columns are nearby and deferred
reshape long Contract_1_  Contract_2_ Implied_Repo_1_ Implied_Repo_2_ Vol_1_ Vol_2_ Price_1_ Price_2_, i(Date) j(Tenor)
rename (Contract_1_ Contract_2_ ) (Contract_1 Contract_2 )
rename (Implied_Repo_1_ Implied_Repo_2_ ) (Implied_Repo_1 Implied_Repo_2)
rename (Vol_1_ Vol_2_ ) (Vol_1 Vol_2)
rename (Price_1_ Price_2_ ) (Price_1 Price_2)

*** Earliest data for nearby implied repo rate is in June 2004
drop if Date <= mdy(6,22,2004)

***** Compute time to maturity for the nearby and deferred contract 
forvalues v = 1(1)2 {
	gen Mat_Month = 12 if substr(Contract_`v',1,3) == "DEC"
	replace Mat_Month = 3 if substr(Contract_`v',1,3) == "MAR"
	replace Mat_Month = 6 if substr(Contract_`v',1,3) == "JUN"
	replace Mat_Month = 9 if substr(Contract_`v',1,3) == "SEP"

	gen Mat_Year = substr(Contract_`v',5,2)
	destring Mat_Year, replace
	replace Mat_Year = Mat_Year + 2000

	joinby Mat_Month Mat_Year using "`Mat_Day'", unmatched(master)
	drop _merge

	**** for contracts that have yet to have a last business day 
	replace Mat_Day = 31 if Contract_`v' == "DEC 21"
	replace Mat_Day = 31 if Contract_`v' == "MAR 22"

	gen Mat_Date_`v' = mdy(Mat_Month, Mat_Day, Mat_Year)
	drop Mat_Month Mat_Day Mat_Year
	format Mat_Date_`v' %d 
	gen TTM_`v' = Mat_Date_`v'-Date
}


**** Compute maturity matched OIS spread 
rename Date date
merge m:1 date using "input/USD_OIS_Rates.dta", keep(3) nogen
forvalues v = 1(1)2 {
	gen OIS_`v' = OIS_1W if TTM_`v' <= 7
	replace OIS_`v' = ((30-TTM_`v')/23)*OIS_1W + ((TTM_`v'-7)/23)*OIS_1M ///
	if TTM_`v' > 7 & TTM_`v' <= 30
	replace OIS_`v' = ((90-TTM_`v')/60)*OIS_1M + ((TTM_`v'-30)/60)*OIS_3M ///
	if TTM_`v' > 30 & TTM_`v' <= 90
	replace OIS_`v' = ((180-TTM_`v')/90)*OIS_3M + ((TTM_`v'-90)/90)*OIS_6M ///
	if TTM_`v' > 90 & TTM_`v' <= 180
	replace OIS_`v' = ((360-TTM_`v')/180)*OIS_6M + ((TTM_`v'-180)/180)*OIS_1Y ///
	if TTM_`v' > 180
}
drop OIS_1W-OIS_30Y

*** Compute Treasury spot-futures arb spread for the nearby and deferred 
gen Arb_N = (Implied_Repo_1-OIS_1)*100 //in basis points 
gen Arb_D = (Implied_Repo_2-OIS_2)*100 //in basis points 

*We use the deferred contract to avoid issues with cheapest-to-deliver
gen arb = Arb_D

*Outlier cleanup following Barndorff-Nielsen et al. (2009)
xtset Tenor date
rangestat (median) arb, by(Tenor) interval(date -45 45) excludeself
gen abs_dev = abs(arb - arb_median)
rangestat (mean) mad=abs_dev, by(Tenor) interval(date -45 45) excludeself
gen bad_price = (abs_dev/mad) >= 10
replace bad_price = . if mi(arb)
replace arb = . if bad_price==1  & !missing(bad_price)  

* Drop data if there is no trading volume in the deferred contract. Note this
* strongly impacts the 30-year (~30% of data).
drop if mi(Vol_2)

*Plot for sanity checks
foreach m in 2 5 10 20 30 {
	twoway line arb date if Tenor == `m', ///
		ytitle("Arbitrage Spread (bps)") xtitle("") ///
		title("Tenor = `m' years")
	graph export "output/arbitrage_spread_`m'.pdf", as(pdf) replace
}

* Define variables for output, rescale to basis points
gen T_SF_Rf = Implied_Repo_2 * 100
replace T_SF_Rf = . if bad_price == 1 & !missing(bad_price)

gen rf_ois_t_sf_mat = OIS_2 * 100
gen T_SF_TTM = TTM_2

aorder 
order date, first
keep date Tenor T_SF_Rf rf_ois_t_sf_mat T_SF_TTM
rename T_SF_Rf T_SF_Rf_
rename rf_ois_t_sf_mat tfut_ois_
rename T_SF_TTM T_SF_TTM_
reshape wide T_SF_Rf_ tfut_ois_ T_SF_TTM_, i(date ) j(Tenor)

*** Cleanup
*Note: Variables with prefix tfut_ois can be used as the reference rate 
*      for computing arbitrage since tenors of each contract are not constant

rename (T_SF_Rf_2 T_SF_Rf_5 T_SF_Rf_10 T_SF_Rf_20 T_SF_Rf_30) ///
	   (tfut_2_rf tfut_5_rf tfut_10_rf tfut_20_rf tfut_30_rf)
	   
rename (T_SF_TTM_2 T_SF_TTM_5 T_SF_TTM_10 T_SF_TTM_20 T_SF_TTM_30) ///
	   (tfut_2_ttm tfut_5_ttm tfut_10_ttm tfut_20_ttm tfut_30_ttm)
	   
label var tfut_2_rf "Treasury 2Y SF RF"
label var tfut_5_rf "Treasury 5Y SF RF"
label var tfut_10_rf "Treasury 10Y SF RF"
label var tfut_20_rf "Treasury 20Y SF RF"
label var tfut_30_rf "Treasury 30Y SF RF"
rename *, lower


* ------------------------------------------------------------------------------
* Output
* ------------------------------------------------------------------------------	
*Save
compress
save "output/treasury_sf_implied_rf.dta", replace
