*! Attaullah Shah, attaullah.shah@imsciences.edu.pk
*! Version 2.0, July 29, 2020

* Version 1.0, 30September2017
cap prog drop asgen
prog asgen, sortpreserve byable(onecall)
	syntax namelist =/ exp [if] [in], [Weights(varname) by(varlist) XFocal]
	
	marksample touse
	
	
	if "`_byvars'"!="" {
		local by "`_byvars'"
	}
	if "`by'"=="" {
		tempvar by
		qui gen `by' = 1
	}
	if "`weights'"	!= "" {	
		qui bys `by' `touse': gen double `namelist' = sum((`exp') * `weights') / ///
		sum(`weights' * !missing(`exp')) if `touse' 
	}
	else {
		qui bys `by' `touse': gen double `namelist' = sum(`exp') / ///
		sum(!missing(`exp')) if `touse' 
	}
	qui bys `by' `touse' : replace `namelist' = `namelist'[_N]

end

exit


/* Acknowledgements: 
This program is mostly similar to _gwmean.ado program, 
except that it does not use egen and hence offers some speed 
efficiency by avaoiding the egen's overhead */
