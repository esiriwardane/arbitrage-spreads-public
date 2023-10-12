clear all
set more off, perm

version 17

adopath - PERSONAL
adopath - OLDPLACE
adopath - SITE

sysdir set PLUS "../lib/ado"

program main
	* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	* Add required packages from SSC to this list
	* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	local ssc_packages reghdfe ftools ivreghdfe grstyle palettes colrspace gtools egen egenmore asgen tsegen estout labutil winsor2 binscatter freduse rangestat
	
    if !missing("`ssc_packages'") {
        foreach pkg in `ssc_packages' {
			capture which `pkg'
			if _rc == 111 {			
				dis "Installing `pkg'"
                quietly ssc install `pkg', replace
			}
        }
    }

    * Install packages using net
    capture which yaml
    if _rc == 111 {
        quietly net from "https://raw.githubusercontent.com/gslab-econ/stata-misc/master/"
        quietly cap ado uninstall yaml
        quietly net install yaml
    }
	
	* Install Gslab packages
	net from "https://raw.githubusercontent.com/gslab-econ/gslab_stata/master/gslab_misc/ado"
	net install benchmark,             replace
	net install build_recode_template, replace
	net install cf_mg,                 replace
	net install checkdta,              replace
	net install cutby,                 replace
	net install dta_to_txt,            replace
	net install dummy_missings,        replace
	net install fillby,                replace
	net install genlistvar,            replace
	net install insert_tag,            replace
	net install leaveout,              replace
	net install load_and_append,       replace
	net install loadglob,              replace
	net install matrix_to_txt,         replace
	net install oo,                    replace
	net install ooo,                   replace
	net install oooo,                  replace
	net install plotcoeffs_nolab,      replace
	net install plotcoeffs,            replace
	net install predict_list,          replace
	net install preliminaries,         replace
	net install rankunique,            replace
	net install ren_lab_file,          replace
	net install save_data,             replace
	net install select_observations,   replace
	net install sortunique,            replace
	net install testbad,               replace
	net install testgood,              replace	
	
end

main
