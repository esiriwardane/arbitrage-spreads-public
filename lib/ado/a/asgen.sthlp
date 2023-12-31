{smcl}
{right:version:  2.0.0}
{cmd:help asgen} {right:July 29, 2020}
{hline}

{title:Title}

{p 4 8}{cmd:asgen}  -  Generates a weighted average mean using an existing variable as a weight {p_end}


{title:Syntax}

{p 8 15 2}
[{help bysort} varlist]: {cmd:asgen}
{newvar} {cmd:=} {it:{help exp}}
{ifin}
[{cmd:,} {it:weight(varname)}
{it:{help by}}({it:varlist})]


{title:Description}

{p 4 4 2} {cmd: asgen} creates a new variable from an existing variable or an
 expression. The new variable contains a weighted average mean. The existing 
 variable is supplied to {cmd: asgen} by the {help =exp}.
The weights are based on the values of an existing numeric variable, that is 
specified in the {cmdab:w:eight}({it:varname}) option. 
{p_end}


{p 4 4 2} {cmd: asgen} accepts both the {ifin} qualifiers for performing the 
required calculations on a subset of data. Further, the use of {help =exp} can
come handy in many situations where we want to make changes on the fly before 
we find the weighted average mean. For example, we might want to multiply
the value of 100 to a variable before we find its weighted average. In such a 
case, the expression will look like:  {p_end}

{p 9 9 2} {hi: asgen wmX = X * 100, w(Y) }{p_end}


{p 4 4 2}  where {hi:{it: wmX}} is a new variable to be created and shall contain
 the weighted average; {hi:{it: X}} and {hi:{it: Y}} are existing variables in the data set. 
{marker asgen_options}{...}
{title:Options}

{p 4 4 2} {opt w:eight(varname)} is an optional option. Therefore, without this 
option, {cmd: asgen} works like {help egen} command and finds simple mean{p_end}

 
{title:Example 1: Weighted average mean for {hi:{it:kstock}} using the variable {hi:{it:mvalue}} as a weight}
 {p 4 8 2}{stata "webuse grunfeld" :. webuse grunfeld}{p_end}
 {p 4 8 2}{stata "asgen WM_kstock = kstock, w(mvalue)" :. asgen WM_kstock = kstock, w(mvalue)} {p_end}


{title:Example 2: Weighted average mean using an expression}

{p 4 8 2}{stata "asgen WM_kstock2 = kstock/invest , w(mvalue)" :. asgen WM_kstock = kstock / invest, w(mvalue)} {p_end}

{p 4 8 4} This will divide the variable {it:kstock} on the variable {it:invest} before finding the weighted average mean. 
 
{title:Example 3: Avoiding the use of [if] using an expression}

{p 4 4 4} We use the {help [if]} qualifier to perform calculation on a subset of
 the data. Using {help [if]} condition,
the resulting variable will have missing values where the condition is not true. 
There might be circumstances where we want to use [if] without encountering
missing values in the new variable. The use of expression can come very handy 
in such a situation. To proceed with an example, let us use {stata "ssc des astile":astile }
[can be downloaded from ssc by clicking here {stata "ssc install astile":install
 astile}] to make five groups of firms based on {it:mvalue} and five groups based
{it:kstock}. {p_end}

{p 4 8 2}{stata "astile size5 =mvalue, nq(5)" :. astile size5 = mvalue, nq(5)} {p_end}
{p 4 8 2}{stata "astile kstock5 =kstock, nq(5)" :. astile kstock5 = kstock, nq(5)} {p_end}

 
 {p 4 4 4} Now, let's find weighted average mean in each year for a combination
 of firms that are in the first quantile of {it:mvalue (size == 1)} and third quantile
 of {it:kstock (kstock5 == 3)} using {it:mvalue} as a weighting variable {p_end}
 
 
{p 4 8 2}{stata "bys year: asgen WM_invest = (kstock / (size5 ==1 & kstock5==3)) , w(mvalue)" :. bys year: asgen WM_invest = (kstock / (size5 ==1 & kstock5==3)), w(mvalue)} {p_end}

{p 4 4 4}  Off-course, we could have done that using [if] qualifier, but that 
will generate missing values where the condition is not true{p_end}

{p 4 8 2}{stata "bys year: asgen WM_invest_IF = kstock if size5 ==1 & kstock5==3, w(mvalue)" :. bys year: asgen WM_invest_IF = kstock if size5 ==1 & kstock5==3 , w(mvalue)} {p_end}

{p 4 4 4} The difference between {it:WM_invest} and {it:WM_invest_IF} is that 
the former spreads the results within years, and the latter does not. 
The use of this trick is borrowed from the behavior of {help egen}. Further 
details related to this trick can be 
read {browse "https://ideas.repec.org/a/tsj/stataj/v11y2011i2p305-314.html": here}
 in Nick Cox's column. 
{p_end}                                 


{title:ONLINE HELP}
{p 4 4 4} You may like to visit {browse "http://FinTechProfessor.com": www.FinTechProfessor.com}.
On this website, I regularly post blog posts and examples related to my programs.
I also maintain users' forums for these programs where users can post comments / questions / answers.
The link to the asgen's forum
is {browse "https://fintechprofessor.com/forums/forum/asgen-program-for-the-weighted-average-mean-in-stata/" : here}
{p_end}                                



{title:Author}


::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::: *
*                                                                   *
*            Dr. Attaullah Shah                                     *
*            Institute of Management Sciences, Peshawar, Pakistan   *
*            Email: attaullah.shah@imsciences.edu.pk                *
*           {browse "www.OpenDoors.Pk": www.OpenDoors.Pk}                                       *
*           {browse "www.StataProfessor.com": www.FinTechProfessor.com}                               *
*:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::*


{marker also}{...}
{title:Also see}

{psee}
{browse "http://www.opendoors.pk/home/paid-help-in-empirical-finance/stata-program-to-construct-j-k-overlappy-momentum-portfolios-strategy": asm    : for momentum portfolios}   {p_end}
{psee}{stata "ssc desc asdoc":asdoc : Easily create publication-quality tables from Stata } {p_end}
{psee}{stata "ssc desc astile":astile : for creating fastest quantile groups} {p_end}
{psee}{stata "ssc desc asreg":asgen : for weighted average mean} {p_end}
{psee}{stata "ssc desc asrol":asrol : for rolling-window statistics} {p_end}
{psee}{stata "ssc desc asreg":asreg : for rolling-window, by-group, and Fama and MacBeth regressions} {p_end}
{psee}{stata "ssc desc ascol":ascol : for converting asset returns and prices from daily to a weekly, monthly, quarterly, and yearly frequency}{p_end}
{psee}{stata "ssc desc searchfor":searchfor : for searching text in data sets} {p_end}





