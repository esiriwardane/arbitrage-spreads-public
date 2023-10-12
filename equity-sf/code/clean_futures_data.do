/*
Create dataset  of SP futures prices containing:
	1. Name of contract (e.g., DM1 Index)
	2. Date
	3. Maturity
	4. Futures Price 
	5. Realized dividend until maturity
*/

adopath + "input/lib/stata"
standardize_env 
est drop _all

*Define files for future prices, dividends, and maturity information
local data_file "input\equity_spot_futures.xlsx"

foreach sheet_name in "SP" "Nasdaq" "DowJones"{
	
	* --------------------------------------------------------------------------
	* Spot and dividend prices
	* --------------------------------------------------------------------------
	import excel "`data_file'", sheet(`sheet_name') cellrange(A6) firstrow clear
	rename (Dates PX_LAST IDX_EST_DVD_YLD INDX_GROSS_DAILY_DIV) ///
		   (Date Spot_Price Div_Yield Daily_Div)
	keep Date-Daily_Div
	destring Spot_Price, replace force
	destring Div_Yield, replace force
	drop if mi(Date) | mi(Spot_Price)
	
	tempfile Spot_Dividend
	save `Spot_Dividend', replace

	* --------------------------------------------------------------------------
	* Futures prices
	* --------------------------------------------------------------------------
	import excel "`data_file'", sheet(`sheet_name') cellrange(A6) firstrow clear
	drop Dates PX_LAST IDX_EST_DVD_YLD INDX_GROSS_DAILY_DIV
	drop E F G
	rename H Date

	rename (I PX_VOLUME OPEN_INT CURRENT_CONTRACT_MONTH_YR) ///
		   (F_P1 Vol1 OI1 Contract1)
	rename (M N O P) (F_P2 Vol2 OI2 Contract2)
	rename (Q R S T) (F_P3 Vol3 OI3 Contract3)
	rename (U V W X) (F_P4 Vol4 OI4 Contract4)

	drop if missing(Date)
	
	destring F_P1 F_P2 F_P3 F_P4, replace force
	destring Vol1 Vol2 Vol3 Vol4, replace force
	destring OI1 OI2 OI3 OI4, replace force
	reshape long F_P Vol OI Contract, i(Date) j(Term)

	drop if Contract==".NA."
	drop if missing(F_P)
	tempfile Futures
	save `Futures', replace

	* --------------------------------------------------------------------------
	* Process contract maturity dates
	* --------------------------------------------------------------------------

	* ---- Get Third Friday of each month for full sample period ---- *

	*Get beginning and end of sample
	egen min_date = min(Date)
	egen max_date = max(Date)

	*Reshape panel to have enough space for all interim dates
	gen ddiff = max_date - min_date
	qui sum ddiff
	local nobs = r(mean)

	if `nobs' < _N keep if _n <= `nobs'
	else set obs `nobs'

	*Generate full time series of dates
	gen all_dates = min_date + _n - 1
	format all_dates %td
	keep all_dates

	*Now get third Friday of each month
	gen day = dow(all_dates)
	gen mat_ym = mofd(all_dates)
	format mat_ym %tm

	bysort mat_ym : gen fricount = sum(day == 5)
	by mat_ym : gen fri3 = (fricount == 3) & (fricount[_n-1] != 3)
	keep if fri3 == 1 

	*Save third Friday of every month as the contract maturity
	rename all_dates maturity
	gen date = maturity 		// Use later when dealing with dividend rolls
	keep maturity 
	rename maturity Date
	gen Mofd=mofd(Date)
	tempfile third_friday
	save `third_friday'

	**** merge maturity 
	use `Futures', clear
	**** Contract maturity
	gen M=substr(Contract,1,3)
	gen Month=.
	replace Month=12 if M=="DEC"
	replace Month=9 if M=="SEP"
	replace Month=6 if M=="JUN"
	replace Month=3 if M=="MAR"
	gen Y=substr(Contract,5,2)
	replace Y="" if missing(Month)
	destring Y, replace
	gen Year=Y+2000 if Y<90
	replace Year=Y+1900 if Y>=90

	gen Mat=mdy(Month, 1, Year)
	format Mat %d
	drop Contract
	drop Month M Year Y

	**** also settles on the third friday 
	*https://www.cmegroup.com/trading/equity-index/us-index/e-mini-dow_contract_specifications.html 
	rename Date Date_P
	gen Mofd=mofd(Mat)
	drop Mat
	joinby Mofd using `third_friday', unmatched(master)
	rename Date Mat
	drop _merge Mofd
	rename Date_P Date
	save `Futures', replace

	* --------------------------------------------------------------------------
	* Perfect foresight dividends (realized)
	* --------------------------------------------------------------------------
	use `Futures', clear
	keep Mat
	sort Mat
	keep if Mat!=Mat[_n-1]
	tempfile Mat
	save `Mat', replace 

	use `Spot_Dividend', clear
	rename Date Mat
	joinby Mat using `Mat', unmatched(both)
	rename Mat Date
	sort Date 
	replace Daily_Div=0 if _merge==2 |missing(Daily_Div)
	keep Date Daily_Div _merge
	gen ID= _merge==3 | _merge==2
	drop _merge

	gen ID_Cum=sum(ID)
	gen Mat_Date1=Date[_n+1] if ID_Cum!=ID_Cum[_n+1]

	gsort ID_Cum -Date
	by ID_Cum: egen Mat1=max(Mat_Date1)
	format Mat1 %d
	drop Mat_Date1
	by ID_Cum: gen Div_Sum1=sum(Daily_Div)
	by ID_Cum: egen Div_Sum=sum(Daily_Div)

	sort Date
	gen Div_Sum_N1=Div_Sum[_n+1] if ID_Cum!=ID_Cum[_n+1]
	gsort ID_Cum Date
	by ID_Cum: egen Div_Sum_1N=max(Div_Sum_N1)
	drop Div_Sum_N1

	sort Date
	gen Mat21=Mat1[_n+1] if ID_Cum!=ID_Cum[_n+1]
	gsort ID_Cum Date
	by ID_Cum: egen Mat2=max(Mat21)
	format Mat2 %d
	drop Mat21

	sort Date
	gen Div_Sum_N1=Div_Sum_1N[_n+1] if ID_Cum!=ID_Cum[_n+1]
	gsort ID_Cum Date
	by ID_Cum: egen Div_Sum_2N=max(Div_Sum_N1)
	drop Div_Sum_N1

	sort Date
	gen Mat31=Mat2[_n+1] if ID_Cum!=ID_Cum[_n+1]
	gsort ID_Cum Date
	by ID_Cum: egen Mat3=max(Mat31)
	format Mat3 %d
	drop Mat31

	gen Div_Sum2=Div_Sum1+Div_Sum_1N 
	gen Div_Sum3=Div_Sum1+Div_Sum_1N+Div_Sum_2N

	keep Date Mat1 Mat2  Mat3 Div_Sum1 Div_Sum2 Div_Sum3
	order Date Mat1 Mat2  Mat3 Div_Sum1 Div_Sum2 Div_Sum3, first
	drop if missing(Date)
	reshape long Mat Div_Sum, i(Date) j(ID)

	*** Div earned
	bysort ID Mat: egen Max_Div_Sum=max(Div_Sum)
	gen Div_Earned=Max_Div_Sum-Div_Sum
	drop Max_Div_Sum
	sort ID Date

	drop if mi(Mat)
	tempfile Perfect_Foresight_Div
	save `Perfect_Foresight_Div', replace 

	* --------------------------------------------------------------------------
	* Merge and finalize
	* --------------------------------------------------------------------------
	use `Futures', clear
	merge m:1 Date using `Spot_Dividend', keep(3) nogen keepusing(Spot_Price)
	drop if missing(Mat)
	
	*Plot average volume for documentation purposes
	graph bar (mean) Vol, ///
		over(Term) blabel(bar) ///
		ytitle("Average Trading Volume") ///
		b1title("Relative Maturity of Futures Contract") ///
		title("`sheet_name'")
	graph export "output/`sheet_name'_avg_volume.pdf", as(pdf) replace
	
	*Merge in realized dividends
	merge 1:1 Date Mat using `Perfect_Foresight_Div', keep(3) nogen
	order Date Mat ID, first
	sort Date Mat
	
	/* We retain the nearby and first b/c they are the two most liquid.
	   See bar graphs in output for more details. Drop days without both.
	*/
	keep if Term<=2 | mi(Mat)
	egen contract_check = nvals(Term), by(Date)
	keep if contract_check == 2
	drop contract_check
	
	*Save
	rename Date date
	compress
	save "temp/`sheet_name'_futures.dta", replace
}




