/*
Assemble CDS-Bond Bases for IG and HY
*/

adopath + "input/lib/stata"
standardize_env 
est drop _all

* Load raw data
import excel "input/final_cds_bases.xlsx", first sheet("Bases") clear

* Handle dates
gen d = date(Date, "YMD")
format d %td
drop Date
rename d date

* Drop dates with low number of issuers
drop if issuer_count < 10 | mi(cds_bond_basis)

* Define implied riskless rate (subtract basis since you borrow to finance bond)
gen implied_rf = treas - cds_bond_basis

* Convert to basis points
replace implied_rf = implied_rf * 1e4
replace treas = treas * 1e4

* Reshape wide
keep date cds_bond_basis implied_rf treas RatingBin
reshape wide cds_bond_basis implied_rf treas, i(date) j(RatingBin) string

* Rename and save
rename (cds_bond_basisIG implied_rfIG treasIG) ///
	   (cds_bond_ig cds_bond_ig_rf cds_bond_ig_treas)
rename (cds_bond_basisHY implied_rfHY treasHY) ///
	   (cds_bond_hy cds_bond_hy_rf cds_bond_hy_treas)

label var cds_bond_ig_rf "CDS-Bond IG-Implied Rf"	   
label var cds_bond_hy_rf "CDS-Bond HY-Implied Rf"
label var cds_bond_ig_treas "CDS-Bond IG MM-Treasury"
label var cds_bond_hy_treas "CDS-Bond HY MM-Treasury"

save "output/cds_bond_implied_rf.dta", replace 
