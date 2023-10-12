# Overview
This folder contains the raw data used to construct arbitrage-implied riskless rates.

# Source
## Bloomberg 
Much of the data that we use comes from Bloomberg. Due to our DUAs, we cannot share the raw data publicly. However, in `{root}/raw/bloomberg_templates/` we have created Excel templates will automatically populate if you have the appropriate Bloomberg license and have access to the Bloomberg Excel Plug-in. The specific files that are generated via Bloomberg templates are:
  - `OIS.xlsx`
  - `cip.xlsx`
  - `equity_spot_futures.xlsx`
  - `libor_rate.xlsx`
  - `treasury_inflation_swaps.xlsx`
  - `treasury_spot_futures.xlsx`
  - `treasury_swap.xlsx`

To use this repo, users should copy them to ``{root}/raw`` and then populate them. See the [README](https://github.com/esiriwardane/arbitrage-spreads/blob/main/raw/bloomberg_templates/README.md) in ``{root}/raw/bloomberg_templates`` for more details on how to populate the templates.

## Markit
CDS-Bond bases derive from bond and CDS spreads that we obtain from Markit. We cannot share the underlying Markit data but can share the resulting aggregated CDS-Bond bases.

# When/where obtained & original form of files
`final_cds_bases.xlsx` 
  - This file is based on [v1.0](https://github.com/esiriwardane/cds-bond-basis/releases/tag/v1.0) of a separate repository that we use to build CDS-Bond bases on the HBS Grid. This file was generated on 2021-07-21.

`box_gov_07302019.xlsx` 
  - Downloaded at this [link](https://www.dropbox.com/s/4azld4rt7twjiny/box_gov_07302019.xlsx?dl=0) on 10/1/2021.

`box_spread_extended.csv`
  - This file is based on [v1.0](https://github.com/esiriwardane/arbitrage-spreads-hf/releases/tag/v1.0) of a separate repository that we use to build put-call parity violations for SPX options on the HBS Grid. This file was generated on 2022-08-22.

`feds200628.csv`
  - Downloaded at this [link](https://www.federalreserve.gov/data/nominal-yield-curve.htm) on 4/19/2023

`feds200805.csv`
  - Downloaded at this [link](https://www.federalreserve.gov/data/tips-yield-curve-and-inflation-compensation.htm) on 4/19/2023

# Description
`final_cds_bases.xlsx`
  - CDS-Bond bases for investment grade and high-yield firms. Firms rated CCC or below are excluded due to liquidity reasons. Z-scores and asset-swap spreads (both computed by Markit) are used for the bond-leg of the basis. Maturity-matched CDS spreads (computed by bootstrapping the entire CDS curve and provided by Markit) are used for the CDS-leg. When Markit does not provide CDS spreads, we use a cubic spline to compute a maturity-matched CDS spread for each bond

`box_gov_07302019.xlsx` 
  - Contains implied riskfree rates based on put-call parity in SPX options. See [van Binsbergen, Diamond, and Grotteria (2021)](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=3242836) for complete details. 

`box_spread_extended.csv`
  - Contains implied riskless rates based on put-call parity in SPX options. Extends the methodology of [van Binsbergen, Diamond, and Grotteria (2021)](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=3242836) past 2018. 
 
`feds200628.csv`
  - Zero-coupon nominal Treasury yield curve published by the Federal Reserve Board of Governors

`feds200805.csv`
  - Zero-coupon TIPS yield curve published by the Federal Reserve Board of Governors
