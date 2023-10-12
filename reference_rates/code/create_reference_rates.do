adopath + "input/lib/stata"
standardize_env 
est drop _all

***** Treasury yields from FRED 
// import fed funds and 3M, 6M, 1, 2, 3, 5 10, 20, 30 yr. 
freduse DFF DGS1MO DTB3 DTB6 DGS1 DGS2 DGS3 DGS5 DGS10 DGS20 DGS30, clear
gen Date=dofd(daten)
format Date %d
rename ( DFF DGS1MO DTB3 DTB6 DGS1 DGS2 DGS3 DGS5 DGS10 DGS20 DGS30) ///
 (fed_funds tyield_1M tyield_3M tyield_6M tyield_1Y tyield_2Y tyield_3Y tyield_5Y tyield_10Y tyield_20Y tyield_30Y) 

drop date daten
drop if missing(tyield_10Y)
order Date tyield_30Y tyield_20Y tyield_10Y tyield_5Y tyield_3Y tyield_2Y tyield_1Y tyield_6M tyield_3M tyield_1M fed_funds, first

rename Date date
save "output/Treasury_Yields", replace

***** OIS Rates 
import excel "input\OIS.xlsx", sheet("Sheet1") cellrange(E7) clear

rename (E F G H I J K L M N O P Q R S T ) /// 
(Date OIS_1W OIS_1M OIS_2M OIS_3M ///
OIS_6M OIS_1Y OIS_2Y OIS_3Y OIS_4Y ///
OIS_5Y OIS_7Y OIS_10Y OIS_15Y OIS_20Y OIS_30Y )


foreach v in OIS_1W  OIS_1M OIS_2M OIS_3M ///
OIS_6M OIS_1Y OIS_2Y OIS_3Y OIS_4Y OIS_5Y ///
OIS_7Y OIS_10Y OIS_15Y OIS_20Y OIS_30Y {
	destring `v', replace force 
}

rename Date date
save "output/USD_OIS_Rates", replace


***** LIBOR Rates 
import excel "input\libor_rate.xlsx", sheet("Sheet1") cellrange(E7) clear

rename (E F G H I J K L) /// 
	(Date Libor_ON Libor_1W Libor_1M Libor_2M Libor_3M ///
	 Libor_6M Libor_1Y)

foreach v in Libor_ON Libor_1W Libor_1M Libor_2M Libor_3M ///
Libor_6M Libor_1Y {
	destring `v', replace force 
}

rename Date date
save "output/USD_LIBOR_Rates", replace


