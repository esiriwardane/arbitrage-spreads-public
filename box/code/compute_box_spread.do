/*
SPX-Option Box Spreads following Van Binsbergen, Diamond, and Grotteria 
	(VDG, 2021)
*/

adopath + "input/lib/stata"
standardize_env 
est drop _all

* Load internally computed series (for extending VDG series)
import delimited "input/box_spread_extended.csv", clear
gen d=date(date, "YMD")
drop date 
rename d Date
format Date %td

foreach v of varlist ts_rate_6m ts_rate_12m ts_rate_18m {
	replace `v' = `v' * 1e4
} 

tempfile internal_box
save `internal_box'

* Load data, destring, and clean up dates/names 
import excel "input/box_gov_07302019.xlsx", sheet("box_gov_l") firstrow clear
keep year month day box_6m box_12m box_18m 
gen Date = mdy(month, day, year)
format Date %td
destring box_18m, replace force

rename (box_6m box_12m box_18m) (box_6m_rf box_12m_rf box_18m_rf)
keep Date box_6m_rf box_12m_rf box_18m_rf

label var box_6m "SPX Option-Implied 6M Rf"
label var box_12m "SPX Option-Implied 12M Rf"
label var box_18m "SPX Option-Implied 18M Rf"

*Convert to basis points
foreach v of varlist box_6m box_12m box_18m {
	replace `v' = `v' * 1e2
} 

*Compare to internal series, then replace missings with internal series
merge 1:1 Date using `internal_box', nogen

foreach m in 6m 12m 18m {
	regress box_`m' ts_rate_`m'
	local b: display %9.2f _b[ts_rate_`m']
	local a: display %9.2f _b[_cons]
	local r2: display %9.4f e(r2)
	twoway (scatter box_`m' ts_rate_`m') || (lfit box_`m' ts_rate_`m'), ///
		ytitle("VDG `m' (bps)") ///
		xtitle("SSW `m' (bps)") ///
		legend(off) ///
		text(100 400 "a = `a'") text(70 400 "b = `b'") text(40 400 "R2 = `r2'")
	graph export "output/vdg_vs_ssw_`m'.pdf", replace 	
}

*Extend VDG series past March 19
foreach m in 6m 12m 18m {
	replace box_`m' = ts_rate_`m' if Date >= mdy(3, 20, 2018)
}

drop ts*

*Save
rename *, lower
compress
save "output/box_spreads.dta", replace
