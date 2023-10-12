/*
Creates new scheme bsplot for stata plots. By default, the new scheme is
saved in lib/stata/
*/


clear all
set more off

* ----------------------------
* Set plot parameters
* ----------------------------

* Background and color schemes
capture grstyle init bsplot, path("../lib/stata/") replace
grstyle color background white
grstyle color plotregion white
grstyle set color tableau
graph set eps fontface "Times New Roman"

* PDF fonts can't be set globally (Stata quirk), so define for each plot
global tgt_font `" "Times New Roman" "'
	

